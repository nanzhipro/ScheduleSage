import SwiftUI
import SwiftWebCrawler
import OSLog

// MARK: - PopoverViewModel
@MainActor
class PopoverViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var showEventList = false
    @Published var isDragging = false
    @Published var dragAnimation: DragAnimation = .none
    @Published var isOCRProcessing = false
    @Published var showUpgradeSheet = false
    @Published var showManualInputSheet = false
    @Published private(set) var canImport = false
    @Published private(set) var proStatus: ProStatus
    @Published var llmResponse: String = ""
    @Published var isLLMProcessing = false
    @Published var parsedEvents: [CalendarEvent] = []
    @Published var importStatus: ImportStatus = .none
    @Published var showToast = false
    @Published var toastMessage = ""
    @Published var toastType: ToastType = .success
    
    // MARK: - Import Status
    enum ImportStatus: Equatable {
        case none
        case importing
        case success
        case failure(Error)
        
        static func == (lhs: ImportStatus, rhs: ImportStatus) -> Bool {
            switch (lhs, rhs) {
            case (.none, .none):
                return true
            case (.importing, .importing):
                return true
            case (.success, .success):
                return true
            case (.failure, .failure):
                // 注意：这里我们只比较是否都是失败状态，不比较具体错误
                // 因为 Error 协议没有遵循 Equatable
                return true
            default:
                return false
            }
        }
    }
    
    // MARK: - Private Properties
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "ScheduleSage", category: "PopoverViewModel")
    private let processor = OCRProcessor()
    private let clipboardManager = ClipboardManager()
    private var promptViewModel: PromptViewModel
    private let webCrawler: WebCrawler = {
        let config = CrawlerConfiguration(
            obeyRobotsTxt: false,
            userAgent: "ScheduleSage/1.0",
            minRequestInterval: 1.0,
            proxy: nil,
            maxConcurrentTasks: 3
        )
        return WebCrawler(configuration: config)
    }()
    private let llmService = LLMService.shared
    private let minimumLoadingDuration: TimeInterval = 1.2
    private var loadingStartTime: Date?
    private let calendarManager = CalendarManager()
    let llmProcessor: LLMEventProcessor
    
    // MARK: - Initialization
    init(proStatus: ProStatus = .free(remainingUses: 12)) {
        self.proStatus = proStatus
        self.promptViewModel = PromptViewModel()
        self.llmProcessor = DefaultLLMEventProcessor(promptViewModel: self.promptViewModel)
        
        Task {
            logger.info("Loading initial prompt...")
            await promptViewModel.loadInitialPrompt()
            await promptViewModel.refreshPrompt()
            logger.info("Initialization completed")
        }
    }
    
    // MARK: - Window State Handling
    func handlePopoverDisappear() {
        // 确保所有 sheet 和状态都被重置
        Task { @MainActor in
            showManualInputSheet = false
            showEventList = false
            showUpgradeSheet = false
            resetState()
        }
    }
}

// MARK: - Animation Types
extension PopoverViewModel {
    enum DragAnimation {
        case none, pulse, bounce, glow, scale
        
        var animation: Animation {
            switch self {
            case .none: return .default
            case .pulse: return Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)
            case .bounce: return Animation.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0.3)
            case .glow: return Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true)
            case .scale: return Animation.easeInOut(duration: 0.5)
            }
        }
    }
}

// MARK: - Clipboard Handling
extension PopoverViewModel {
    func checkClipboardContent() {
        guard let content = clipboardManager.checkClipboard() else {
            showInvalidURLToast()
            return
        }
        
        switch content {
        case .url(let url):
            logger.debug("URL content detected: \(url.absoluteString)")
            handleURLContent(url)
        case .image(let url):
            logger.debug("Image content detected: \(url.path)")
            handleImageContent(url)
        }
    }
    
    private func showInvalidURLToast() {
        showToast = false
        toastType = .error
        toastMessage = NSLocalizedString("invalid_clipboard_url", comment: "")
        
        DispatchQueue.main.async {
            self.showToast = true
        }
    }
    
    private func handleURLContent(_ url: URL) {
        guard url.isValidWebURL else {
            self.logger.error("Invalid URL format: \(url.absoluteString)")
            showInvalidURLToast()
            return
        }
        
        Task {
            await MainActor.run { LoadingManager.shared.show(.processing) }
            
            do {
                if try await URLHeaderInspector.shared.isImageURL(url) {
                    self.logger.info("Processing URL as image: \(url.absoluteString)")
                    await self.handleImageURL(url)
                } else if try await URLHeaderInspector.shared.isHTMLPage(url) {
                    self.logger.info("Processing URL as webpage: \(url.absoluteString)")
                    await self.handleWebContent(url)
                } else {
                    self.logger.notice("Unsupported content type at URL: \(url.absoluteString)")
                    await self.updateState(loading: false, canImport: false)
                    showInvalidURLToast()
                }
            } catch {
                await self.handleError(error)
                showInvalidURLToast()
            }
        }
    }
}

// MARK: - Content Processing
extension PopoverViewModel {
    private func handleWebContent(_ url: URL) async {
        do {
            await MainActor.run { 
                self.isLLMProcessing = true
                LoadingManager.shared.show(.processing) 
            }
            
            let results = await self.webCrawler.crawlBatch(urls: [url.absoluteString])
            guard let result = results[url.absoluteString] else {
                throw PromptError.invalidResponse
            }
            
            let contentText = try result.get()
            
            do {
                let events = try await llmProcessor.processContent(contentText)
                
                await MainActor.run {
                    self.parsedEvents = events
                    self.isLLMProcessing = false
                    LoadingManager.shared.hide()
                    self.canImport = true
                    self.showEventList = true
                }
                
                logger.info("Web content processing completed successfully")
            } catch let error as LLMEventProcessorError {
                logger.error("LLM processing failed: \(error.localizedDescription)")
                await MainActor.run {
                    self.isLLMProcessing = false
                    LoadingManager.shared.hide()
                    self.showToast = false
                    self.toastType = .error
                    self.toastMessage = error.localizedDescription
                    self.showToast = true
                }
            }
            
        } catch {
            logger.error("Web content processing failed: \(error.localizedDescription)")
            await self.handleError(error)
        }
    }
    
    private func handleImageContent(_ url: URL) {
        guard url.isValidImageFile else {
            logger.error("Invalid image file: \(url.path)")
            return
        }
        
        Task {
            logger.info("Starting OCR processing for image: \(url.path)")
            await startOCRProcessing()
            
            do {
                let results = try await processor.process(imagePath: url.path) { progress in
                    self.logger.debug("OCR Progress: \(Int(progress * 100))%")
                }
                
                await completeOCRProcessing(with: results)
                logger.info("OCR processing completed successfully")
            } catch {
                logger.error("OCR processing failed: \(error.localizedDescription)")
                await handleError(error)
            }
            
            try? FileManager.default.removeItem(atPath: url.path)
            logger.debug("Temporary image file removed")
        }
    }
    
    private func handleImageURL(_ url: URL) async {
        await MainActor.run { LoadingManager.shared.show(.network) }
        
        do {
            let results = try await processor.process(imagePath: url.path) { progress in
                print("OCR Progress: \(progress * 100)%")
            }
            await completeOCRProcessing(with: results)
        } catch {
            await handleError(error)
        }
    }
}

// MARK: - State Management
extension PopoverViewModel {
    private func startOCRProcessing() async {
        await MainActor.run {
            loadingStartTime = Date()
            isOCRProcessing = true
            LoadingManager.shared.show(.ocr)
        }
    }
    
    private func completeOCRProcessing(with results: [OCRLanguage: [OCRResult]]) async {
        let elapsedTime = Date().timeIntervalSince(loadingStartTime ?? Date())
        let additionalDelay = max(0, minimumLoadingDuration - elapsedTime)
        try? await Task.sleep(nanoseconds: UInt64(additionalDelay * 1_000_000_000))
        
        await MainActor.run {
            processor.printDetailedResults(results)
            let allTexts = processor.getAllTexts(from: results)
            
            isOCRProcessing = false
            LoadingManager.shared.hide()
            canImport = !allTexts.isEmpty
        }
    }
    
    private func updateState(loading: Bool, canImport: Bool) async {
        await MainActor.run {
            if loading {
                LoadingManager.shared.show(.processing)
            } else {
                LoadingManager.shared.hide()
            }
            self.canImport = canImport
        }
    }
    
    private func handleError(_ error: Error) async {
        logger.error("Operation failed: \(error.localizedDescription)")
        await MainActor.run {
            isOCRProcessing = false
            isLLMProcessing = false
            LoadingManager.shared.hide()
            canImport = false
        }
    }
}

// MARK: - Drag and Drop
extension PopoverViewModel {
    func handleDragEntered() {
        isDragging = true
        dragAnimation = .glow
    }
    
    func handleDragExited() {
        isDragging = false
        dragAnimation = .none
    }
    
    func handleDropped(_ urls: [URL]) {
        guard let url = urls.first else { return }
        Task { @MainActor in
            loadingStartTime = Date()
            isOCRProcessing = true
            LoadingManager.shared.show(.ocr)
            
            isDragging = false
            dragAnimation = .none
        }
        handleImageContent(url)
    }
    
    func resetState() {
        showEventList = false
        isDragging = false
        dragAnimation = .none
        isOCRProcessing = false
        canImport = false
        parsedEvents.removeAll()
        importStatus = .none
        showManualInputSheet = false
        // checkClipboardContent()
    }
}

// MARK: - Pro Features
extension PopoverViewModel {
    func showUpgradeSheetAction() {
        showUpgradeSheet = true
    }
    
    func canPerformAction(_ action: ProFeature.Action) -> Bool {
        if proStatus.isPro { return true }
        
        switch action {
        case .ocr: return proStatus.remainingUses ?? 0 > 0
        case .export: return true
        case .advanced: return false
        }
    }
}

// MARK: - Helper Extensions
private extension URL {
    var isValidWebURL: Bool {
        guard let scheme = scheme?.lowercased() else { return false }
        return ["http", "https"].contains(scheme) && !absoluteString.isEmpty
    }
    
    var isValidImageFile: Bool {
        FileManager.default.fileExists(atPath: path) && 
        ImageSupport.isSupported(extension: pathExtension)
    }
}

// MARK: - Private Helper Methods
private extension PopoverViewModel {
    func getCalendarNames() async -> [String] {
        do {
            // 请求日历访问权限
            guard try await calendarManager.requestAccess() else {
                logger.error("Calendar access denied")
                return []
            }
            
            // 获取所有日历名称
            let calendarNames = calendarManager.getAllCalendarNames()
            logger.debug("Retrieved calendar names: \(calendarNames)")
            return calendarNames
            
        } catch {
            logger.error("Failed to get calendar names: \(error.localizedDescription)")
            return []
        }
    }
    
    private func buildPromptWithContent(_ content: String, calendarNames: [String]) async throws -> String {
        // 获取基础提示词
        let basePrompt = await promptViewModel.getPromptContent()
        
        // 构建日历名称列表字符串
        let calendarList = calendarNames.isEmpty ? "Default Calendar" : calendarNames.joined(separator: ", ")
        
        // 替换占位符
        let promptWithCalendars = basePrompt.replacingOccurrences(
            of: "CALENDAR_NAMES_LIST",
            with: calendarList
        )
        
        // 替换内容占位符
        let finalPrompt = promptWithCalendars.replacingOccurrences(
            of: "PLACEHOLDER_TEXT",
            with: content
        )
        
        return finalPrompt
    }
}

// MARK: - Calendar Import
extension PopoverViewModel {
    func importToCalendar() {
        Task {
            await MainActor.run {
                importStatus = .importing
                LoadingManager.shared.show(.processing)
            }
            
            do {
                // 请求日历访问权限
                guard try await calendarManager.requestAccess() else {
                    throw CalendarError.accessDenied
                }
                
                // 导入所有事件
                for event in parsedEvents {
                    try await calendarManager.createEvent(from: event)
                }
                
                await MainActor.run {
                    importStatus = .success
                    LoadingManager.shared.hide()
                    // 延迟重置状态，让用户看到成功提示
                    Task {
                        try? await Task.sleep(nanoseconds: 2_000_000_000)  // 2秒后
                        await MainActor.run {
                            resetState()
                        }
                    }
                }
                
            } catch {
                logger.error("Failed to import events: \(error.localizedDescription)")
                await MainActor.run {
                    importStatus = .failure(error)
                    LoadingManager.shared.hide()
                }
            }
        }
    }
}

// MARK: - Calendar Error
enum CalendarError: LocalizedError {
    case accessDenied
    
    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return NSLocalizedString("calendar_access_denied", comment: "")
        }
    }
}

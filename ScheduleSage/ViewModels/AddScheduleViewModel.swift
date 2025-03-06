import SwiftUI
import SwiftWebCrawler
import OSLog
import QuestOCR

// MARK: - AddScheduleViewModel 新增日程 ViewModel
@MainActor
class AddScheduleViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var showEventList = false
    @Published var isDragging = false
    @Published var dragAnimation: DragAnimation = .none
    @Published var isOCRProcessing = false
    @Published var showManualInputSheet = false
    @Published private(set) var canImport = false
    @Published var llmResponse: String = ""
    @Published var isLLMProcessing = false
    @Published var parsedEvents: [CalendarEvent] = []
    @Published var importStatus: ImportStatus = .none
    @Published var showToast = false
    @Published var toastMessage = ""
    @Published var toastType: ToastType = .success
    @Published var isKeyboardMonitorEnabled = true
    @Published var showImagePicker = false
    @Published var feedbackButtonScale: CGFloat = 1.0
    @Published var showPaywall = false
    
    // MARK: - Services & Managers
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "ScheduleSage", category: "AddScheduleViewModel")
    private let processor = OCRProcessor()
    private let clipboardManager = ClipboardManager()
    private let calendarManager = CalendarManager()
    private let webCrawler: WebCrawler
    private let llmProcessor: LLMEventProcessor
    
    // MARK: - Private Properties
    private var promptViewModel: PromptViewModel
    private let minimumLoadingDuration: TimeInterval = 1.2
    private var loadingStartTime: Date?
    
    // MARK: - Initialization
    init() {
        self.promptViewModel = PromptViewModel()
        self.llmProcessor = DefaultLLMEventProcessor(promptViewModel: self.promptViewModel)
        self.webCrawler = Self.createWebCrawler()
        
        Task {
            logger.info("Loading initial prompt...")
            await promptViewModel.loadInitialPrompt()
            await promptViewModel.refreshPrompt()
            logger.info("Initialization completed")
        }
        
        setupNotifications()
    }
    
    private static func createWebCrawler() -> WebCrawler {
        let config = CrawlerConfiguration(
            obeyRobotsTxt: false,
            userAgent: "ScheduleSage/1.0",
            minRequestInterval: 1.0,
            proxy: nil,
            maxConcurrentTasks: 3
        )
        return WebCrawler(configuration: config)
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCommandV),
            name: .commandVPressed,
            object: nil
        )
    }
    
    @objc private func handleCommandV() {
        guard isKeyboardMonitorEnabled else { return }
        checkClipboardContent()
    }
    
    // MARK: - Keyboard Monitor Control
    func disableKeyboardMonitor() {
        isKeyboardMonitorEnabled = false
    }
    
    func enableKeyboardMonitor() {
        isKeyboardMonitorEnabled = true
    }
}

// MARK: - Models & Enums
extension AddScheduleViewModel {
    enum ImportStatus: Equatable {
        case none
        case importing
        case success
        case failure(Error)
        
        static func == (lhs: ImportStatus, rhs: ImportStatus) -> Bool {
            switch (lhs, rhs) {
            case (.none, .none), (.importing, .importing), (.success, .success):
                return true
            case (.failure, .failure):
                return true // Error 不遵循 Equatable，只比较类型
            default:
                return false
            }
        }
    }
    
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
extension AddScheduleViewModel {
    func handleClipboardContent(_ content: ClipboardContent) {
        switch content {
        case .url(let url):
            logger.debug("URL content detected from keyboard shortcut: \(url.absoluteString)")
            handleURLContent(url)
        case .image(let url):
            logger.debug("Image content detected from keyboard shortcut: \(url.path)")
            handleImageContent(url)
        }
    }

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
        showToastMessage(NSLocalizedString("invalid_clipboard_content", comment: ""))
    }
    
    func handleURLContent(_ url: URL) {
        guard url.isValidWebURL else {
            logger.error("Invalid URL format: \(url.absoluteString)")
            showInvalidURLToast()
            return
        }
        
        Task {
            await showLoading(.processing)
            
            do {
                if try await URLHeaderInspector.shared.isImageURL(url) {
                    logger.info("Processing URL as image: \(url.absoluteString)")
                    await handleImageURL(url)
                } else if try await URLHeaderInspector.shared.isHTMLPage(url) {
                    logger.info("Processing URL as webpage: \(url.absoluteString)")
                    await handleWebContent(url)
                } else {
                    logger.notice("Unsupported content type at URL: \(url.absoluteString)")
                    await updateState(loading: false, canImport: false)
                    showInvalidURLToast()
                }
            } catch {
                await handleError(error)
                showInvalidURLToast()
            }
        }
    }
}

// MARK: - Content Processing
extension AddScheduleViewModel {
    private func handleWebContent(_ url: URL) async {
        do {
            await setProcessingState(true)
            
            let results = await webCrawler.crawlBatch(urls: [url.absoluteString])
            guard let result = results[url.absoluteString] else {
                throw PromptError.invalidResponse(-1)
            }
            
            let contentText = try result.get()
            let events = try await processContentWithLLM(contentText)
            let eventsWithURL = addURLToEvents(events, url: url)
            
            await updateUIWithEvents(eventsWithURL)
            logger.info("Web content processing completed successfully with \(eventsWithURL.count) events")
        } catch {
            logger.error("Web content processing failed: \(error.localizedDescription)")
            await handleError(error)
        }
    }
    
    private func addURLToEvents(_ events: [CalendarEvent], url: URL) -> [CalendarEvent] {
        return events.map { event in
            var modifiedEvent = event
            if modifiedEvent.url.isEmpty {
                modifiedEvent = CalendarEvent(
                    title: event.title,
                    location: event.location,
                    notes: event.notes,
                    startDate: event.startDate,
                    endDate: event.endDate,
                    url: url.absoluteString,
                    calendar: event.calendar,
                    status: event.status,
                    eventIdentifier: event.eventIdentifier,
                    remarks: event.remarks
                )
            }
            return modifiedEvent
        }
    }
    
    private func handleImageContent(_ url: URL) {
        guard url.isValidImageFile else {
            logger.error("Invalid image file: \(url.path)")
            showToastMessage(NSLocalizedString("invalid_image_format", comment: ""))
            return
        }
        
        Task {
            logger.info("Starting OCR processing for image: \(url.path)")
            await startOCRProcessing()
            
            do {
                let results = try await processor.process(imagePath: url.path)
                await completeOCRProcessing(with: results)
                logger.info("OCR processing completed successfully")
            } catch {
                logger.error("OCR processing failed: \(error.localizedDescription)")
                await handleError(error)
            }
        }
    }
    
    private func handleImageURL(_ url: URL) async {
        await showLoading(.network)
        
        do {
            let results = try await processor.process(imagePath: url.path)
            await completeOCRProcessing(with: results)
        } catch {
            await handleError(error)
        }
    }
    
    private func processContentWithLLM(_ content: String) async throws -> [CalendarEvent] {
        do {
            return try await llmProcessor.processContent(content)
        } catch {
            logger.error("LLM processing failed: \(error.localizedDescription)")
            await MainActor.run {
                self.isLLMProcessing = false
                LoadingManager.shared.hide()
                self.showToast = false
                self.toastType = .error
                self.toastMessage = error.localizedDescription
                self.showToast = true
            }
            throw error
        }
    }
}

// MARK: - State Management
extension AddScheduleViewModel {
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
            
            if !allTexts.isEmpty {
                let combinedText = allTexts.joined(separator: "\n")
                Task {
                    await processWithLLM(combinedText)
                }
            }
        }
    }
    
    private func processWithLLM(_ content: String) async {
        await setProcessingState(true)
        
        do {
            let events = try await llmProcessor.processContent(content)
            await updateUIWithEvents(events)
            logger.info("LLM processing completed successfully with \(events.count) events")
        } catch let error as LLMEventProcessorError {
            logger.error("LLM processing failed: \(error.localizedDescription)")
            await handleError(error)
        } catch {
            logger.error("Unexpected error: \(error.localizedDescription)")
            await handleError(error)
        }
    }
    
    private func setProcessingState(_ isProcessing: Bool) async {
        await MainActor.run {
            isLLMProcessing = isProcessing
            if isProcessing {
                LoadingManager.shared.show(.processing)
            } else {
                LoadingManager.shared.hide()
            }
        }
    }
    
    private func showLoading(_ type: LoadingType) async {
        await MainActor.run { LoadingManager.shared.show(type) }
    }
    
    private func updateUIWithEvents(_ events: [CalendarEvent]) async {
        await MainActor.run {
            self.parsedEvents = events
            self.isLLMProcessing = false
            LoadingManager.shared.hide()
            self.canImport = !events.isEmpty
            self.showEventList = true
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
            
            if let llmError = error as? LLMEventProcessorError,
               case .requiresPremium = llmError {
                showPaywall = true
            } else {
                showToastMessage(error.localizedDescription)
            }
        }
    }
}

// MARK: - Drag and Drop
extension AddScheduleViewModel {
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
        
        guard url.isValidImageFile else {
            logger.error("Invalid image file dropped: \(url.path)")
            showToastMessage(NSLocalizedString("invalid_image_format", comment: ""))
            return
        }
        
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
    }
}

// MARK: - Calendar Operations
extension AddScheduleViewModel {
    private func getCalendarNames() async -> [String] {
        do {
            guard try await calendarManager.requestAccess() else {
                logger.error("Calendar access denied")
                return []
            }
            
            let calendarNames = calendarManager.getAllCalendarNames()
            logger.debug("Retrieved calendar names: \(calendarNames)")
            return calendarNames
            
        } catch {
            logger.error("Failed to get calendar names: \(error.localizedDescription)")
            return []
        }
    }
    
    func importToCalendar() {
        Task {
            await MainActor.run {
                importStatus = .importing
                LoadingManager.shared.show(.processing)
            }
            
            do {
                guard try await calendarManager.requestAccess() else {
                    throw CalendarError.accessDenied
                }
                
                var lastEventId: String?
                for event in parsedEvents {
                    lastEventId = try await calendarManager.createEvent(from: event)
                }
                
                await handleSuccessfulImport(lastEventId: lastEventId)
                
            } catch {
                logger.error("Failed to import events: \(error.localizedDescription)")
                await MainActor.run {
                    importStatus = .failure(error)
                    LoadingManager.shared.hide()
                }
            }
        }
    }
    
    private func handleSuccessfulImport(lastEventId: String?) async {
        await MainActor.run {
            importStatus = .success
            LoadingManager.shared.hide()
            
            if let eventId = lastEventId {
                NotificationManager.shared.sendCalendarEventNotification(
                    title: NSLocalizedString("import_success", comment: "Success message for calendar import"),
                    body: NSLocalizedString("click_to_view_event", comment: "Prompt to view imported event"),
                    eventId: eventId
                )
            }
            
            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000)  // 2秒后
                await MainActor.run {
                    resetState()
                }
            }
        }
    }
    
    func updateEvent(_ updatedEvent: CalendarEvent) {
        logger.info("Updating event: \(updatedEvent.title), \(updatedEvent.startDate), \(updatedEvent.endDate), \(updatedEvent.location), \(updatedEvent.calendar)")
        if let index = parsedEvents.firstIndex(where: { $0.eventIdentifier == updatedEvent.eventIdentifier }) {
            parsedEvents[index] = updatedEvent
            NotificationCenter.default.post(
                name: .eventDidUpdate,
                object: nil,
                userInfo: ["event": updatedEvent]
            )
        }
    }
}

// MARK: - Toast Management
extension AddScheduleViewModel {
    func showToastMessage(_ message: String, type: ToastType = .error, duration: TimeInterval = 2.0) {
        Task { @MainActor in
            showToast = false
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms
            
            toastType = type
            toastMessage = message
            showToast = true
            
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            
            if toastMessage == message {
                showToast = false
            }
        }
    }
    
    func hideAllToasts() {
        Task { @MainActor in
            showToast = false
            importStatus = .none
        }
    }
}

// MARK: - Image Selection
extension AddScheduleViewModel {
    func handleImageSelection() {
        showImagePicker = true
    }
    
    func handleImagePickerResult(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let url = urls.first {
                handleDropped([url])
            } else {
                logger.error("No image selected")
                showToastMessage(NSLocalizedString("no_image_selected", comment: ""))
            }
        case .failure(let error):
            logger.error("Image selection failed: \(error.localizedDescription)")
            showToastMessage(NSLocalizedString("image_selection_failed", comment: ""))
        }
    }
}

// MARK: - Premium Features
extension AddScheduleViewModel {
    func proceedWithProFeature() {
        showPaywall = false
        LoadingManager.shared.hide()
    }
}

// MARK: - Helper Extensions
private extension URL {
    var isValidImageFile: Bool {
        FileManager.default.fileExists(atPath: path) && 
        ImageSupport.isSupported(extension: pathExtension)
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

// MARK: - Notification Name Extension
extension Notification.Name {
    static let commandVPressed = Notification.Name("commandVPressed")
}

// MARK: - Manual Input Processing
extension AddScheduleViewModel {
    func processManualInput(_ text: String) async throws -> [CalendarEvent] {
        return try await llmProcessor.processContent(text)
    }
}

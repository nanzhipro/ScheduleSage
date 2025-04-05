import SwiftUI
import OSLog
import AVFoundation
import AVKit
import AppKit

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
    @Published private(set) var isPremium = false
    @Published var isRecording = false
    @Published var transcribedText = ""
    @Published var audioLevel: Float = 0.0
    @Published var showVoiceRecognitionView = false
    
    // MARK: - Services & Managers
    private let logger = LoggerService.makeCompatible(category: "AddScheduleViewModel")
    private let processor = OCRProcessor()
    private let clipboardManager = ClipboardManager()
    private let calendarManager = CalendarManager()
    private var webCrawler: WebCrawler
    private let llmProcessor: LLMEventProcessor
    private let iapService = IAPService.shared
    private var voiceRecognitionService: VoiceRecognitionServiceProtocol
    
    // MARK: - Private Properties
    private let minimumLoadingDuration: TimeInterval = 1.2
    private var loadingStartTime: Date?
    private var tempImageURLs: [URL] = []
    
    // MARK: - Initialization
    init() {
        llmProcessor = DefaultLLMEventProcessor()
        webCrawler = Self.createWebCrawler()
        voiceRecognitionService = VoiceRecognitionService()
        
        Task {
            logger.info("Initialization completed")
            
            _ = await checkSubscriptionStatus()
        }
        
        setupNotifications()
        setupSubscriptionObserver()
        setupVoiceRecognition()
    }
    
    deinit {
        // 取消网络任务可以在任何线程执行
        webCrawler.session.invalidateAndCancel()
        
        // 清理临时文件
        cleanupFiles(tempImageURLs)
        
        // 使用弱引用避免循环引用
        let weakWebCrawler = webCrawler
        let weakProcessor = processor
        let logger = self.logger
        
        // 避免在Task中捕获self
        Task { @MainActor in
            weakWebCrawler.dispose()
            weakProcessor.cleanup()
            logger.info("AddScheduleViewModel resources cleaned up")
        }
        
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - WebCrawler
    
    private static func createWebCrawler() -> WebCrawler {
        let config = CrawlerConfiguration(
            obeyRobotsTxt: false,
            userAgent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15",
            minRequestInterval: 1.0,
            proxy: nil,
            maxConcurrentTasks: 3
        )
        return WebCrawler(configuration: config)
    }
    
    // MARK: - Notification Setup
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCommandV),
            name: .commandVPressed,
            object: nil
        )
        
        // 监听来自 AppDelegate 的 URL 处理通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleChromeExtensionURL(_:)),
            name: Notification.Name("handleChromeExtensionURL"),
            object: nil
        )
    }
    
    @objc private func handleCommandV() {
        // 当键盘监控被禁用或AI处理中时不响应Command+V
        guard isKeyboardMonitorEnabled && !isLLMProcessing else { return }
        checkClipboardContent()
    }
    
    @objc private func handleChromeExtensionURL(_ notification: Notification) {
        guard let url = notification.userInfo?["url"] as? URL else {
            logger.error("Invalid URL received from AppDelegate")
            showInvalidURLToast()
            return
        }
        
        logger.info("Processing URL from Chrome extension: \(url.absoluteString)")
        handleURLContent(url)
    }
    
    // MARK: - Keyboard Monitor Control
    
    func toggleKeyboardMonitor(isEnabled: Bool) {
        isKeyboardMonitorEnabled = isEnabled
    }
    
    // MARK: - 订阅状态管理
    
    private func setupSubscriptionObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSubscriptionChange),
            name: .subscriptionStatusChanged,
            object: nil
        )
    }
    
    @objc private func handleSubscriptionChange(_ notification: Notification) {
        if let isPremium = notification.userInfo?["isPremium"] as? Bool {
            Task { @MainActor in
                self.isPremium = isPremium
            }
        }
    }

    /// 检查订阅状态
    func checkSubscriptionStatus() async -> Bool {
        do {
            let isPremium = try await iapService.checkSubscriptionStatus()
            logger.info("Subscription status: \(isPremium)")
            
            await MainActor.run {
                self.isPremium = isPremium
            }
            
            return isPremium
        } catch {
            logger.error("Failed to check subscription status: \(error.localizedDescription)")
            
            await MainActor.run {
                self.isPremium = false
            }
            
            return false
        }
    }
    
    /// 打开付费墙
    func showPaywallView() {
        showPaywall = true
    }
    
    // MARK: - 文件管理
    
    /// 清理指定的文件列表，可以在任何线程调用
    nonisolated private func cleanupFiles(_ urls: [URL]) {
        let fileManager = FileManager.default
        
        for url in urls {
            do {
                if fileManager.fileExists(atPath: url.path) {
                    try fileManager.removeItem(at: url)
                    print("Deleted temporary file: \(url.path)")
                }
            } catch {
                print("Failed to delete temporary file \(url.path): \(error.localizedDescription)")
            }
        }
    }

    /// 清理所有临时文件 - 只能在MainActor上调用
    @MainActor
    private func cleanupTempFiles() {
        let filesToDelete = tempImageURLs
        tempImageURLs.removeAll()
        cleanupFiles(filesToDelete)
    }
}

// MARK: - Models & Enums
extension AddScheduleViewModel {
    enum ImportStatus: Equatable {
        case none, importing, success, failure(Error)
        
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
        case .text(let text):
            logger.debug("Text content detected from keyboard shortcut: \(text.prefix(30))...")
            handleTextContent(text)
        }
    }

    func checkClipboardContent() {
        guard let content = clipboardManager.checkClipboard() else {
            showInvalidURLToast()
            return
        }
        
        handleClipboardContent(content)
    }
    
    private func showInvalidURLToast() {
        showToastMessage(NSLocalizedString("invalid_clipboard_content", comment: ""))
    }
    
    /// 处理剪贴板中的纯文本内容
    private func handleTextContent(_ text: String) {
        guard !text.isEmpty else {
            logger.error("Empty text content")
            showToastMessage(NSLocalizedString("empty_text_content", comment: ""))
            return
        }
        
        Task {
            // 使用setProcessingState统一处理处理状态和键盘监控
            await setProcessingState(true)
            
            do {
                let events = try await processWithLLM(text)
                await updateUIWithEvents(events)
                logger.info("Text content processing completed successfully with \(events.count) events")
            } catch {
                logger.error("Text content processing failed: \(error.localizedDescription)")
                await handleError(error)
            }
        }
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
                let urlInspector = URLHeaderInspector.shared
                
                if try await urlInspector.isImageURL(url) {
                    logger.info("Processing URL as image: \(url.absoluteString)")
                    await handleImageURL(url)
                } else if try await urlInspector.isHTMLPage(url) {
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
                throw APIError.invalidResponse(description: "Failed to get crawl result for URL")
            }
            
            let contentText = try result.get()
            // 使用统一的processWithLLM方法处理内容
            let events = try await processWithLLM(contentText)
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
            guard event.url.isEmpty else { return event }
            
            return CalendarEvent(
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
    
    /// 按照开始和结束时间聚合事件，对于时间相同的事件保留第一个
    /// - Parameter events: 原始事件数组
    /// - Returns: 聚合后的事件数组
    private func aggregateEventsByTime(_ events: [CalendarEvent]) -> [CalendarEvent] {
        // 创建一个字典，键为开始和结束时间的组合，值为对应的事件
        var eventMap: [String: CalendarEvent] = [:]
        
        for event in events {
            // 创建时间键
            let timeKey = "\(event.startDate)_\(event.endDate)"
            
            // 如果字典中没有这个时间键，则添加事件
            if eventMap[timeKey] == nil {
                eventMap[timeKey] = event
            }
            // 如果已存在相同时间的事件，保留第一个（不做任何操作）
        }
        
        // 将字典中的事件转为数组并返回
        return Array(eventMap.values)
    }
}

// MARK: - State Management
extension AddScheduleViewModel {
    private func processWithLLM(_ content: String) async throws -> [CalendarEvent] {
        await setProcessingState(true)
        
        do {
            let events = try await llmProcessor.processContent(content)
            logger.info("LLM processing completed successfully with \(events.count) events")
            
            // 对事件进行聚合处理
            let aggregatedEvents = aggregateEventsByTime(events)
            logger.info("Aggregated \(events.count) events to \(aggregatedEvents.count) events")
            
            return aggregatedEvents
        } catch let error as LLMEventProcessorError {
            logger.error("LLM processing failed: \(error.localizedDescription)")
            await handleError(error)
            throw error
        } catch {
            logger.error("Unexpected error: \(error.localizedDescription)")
            await handleError(error)
            throw error
        }
    }
    
    private func startOCRProcessing() async {
        await MainActor.run {
            loadingStartTime = Date()
            isOCRProcessing = true
            // OCR处理期间禁用键盘监控
            isKeyboardMonitorEnabled = false
            LoadingManager.shared.show(.ocr)
        }
    }
    
    private func completeOCRProcessing(with results: [OCRLanguage: [OCRResult]]) async {
        // 确保最小加载时间
        let elapsedTime = Date().timeIntervalSince(loadingStartTime ?? Date())
        let additionalDelay = max(0, minimumLoadingDuration - elapsedTime)
        
        if additionalDelay > 0 {
            try? await Task.sleep(for: .seconds(additionalDelay))
        }
        
        await MainActor.run {
            processor.printDetailedResults(results)
            let formattedText = processor.getFormattedText(from: results)
            
            isOCRProcessing = false
            // OCR处理完成后恢复键盘监控
            isKeyboardMonitorEnabled = true
            LoadingManager.shared.hide()
            
            // 清理资源
            processor.cleanup()
            cleanupTempFiles()
            
            if !formattedText.isEmpty {
                Task {
                    do {
                        let events = try await processWithLLM(formattedText)
                        await updateUIWithEvents(events)
                    } catch {
                        logger.error("Failed to process formatted text: \(error.localizedDescription)")
                        // 错误已在processWithLLM中处理
                    }
                }
            }
        }
    }
    
    private func setProcessingState(_ isProcessing: Bool) async {
        await MainActor.run {
            isLLMProcessing = isProcessing
            // AI处理期间禁用键盘监控
            isKeyboardMonitorEnabled = !isProcessing
            LoadingManager.shared.toggle(show: isProcessing, type: .processing)
        }
    }
    
    private func showLoading(_ type: LoadingType) async {
        await MainActor.run { LoadingManager.shared.show(type) }
    }
    
    private func updateUIWithEvents(_ events: [CalendarEvent]) async {
        await MainActor.run {
            parsedEvents = events
            isLLMProcessing = false
            // 恢复键盘监控
            isKeyboardMonitorEnabled = true
            LoadingManager.shared.hide()
            canImport = !events.isEmpty
            showEventList = true
        }
    }
    
    private func updateState(loading: Bool, canImport: Bool) async {
        await MainActor.run {
            LoadingManager.shared.toggle(show: loading, type: .processing)
            // 处理键盘监控状态
            isKeyboardMonitorEnabled = !loading
            self.canImport = canImport
        }
    }
    
    private func handleError(_ error: Error) async {
        logger.error("Operation failed: \(error.localizedDescription)")
        
        await MainActor.run {
            isOCRProcessing = false
            isLLMProcessing = false
            // 错误处理时重新启用键盘监控
            isKeyboardMonitorEnabled = true
            LoadingManager.shared.hide()
            canImport = false
            
            // 清理资源
            processor.cleanup()
            cleanupTempFiles()
            
            if let llmError = error as? LLMEventProcessorError, case .requiresPremium = llmError {
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
        guard let url = urls.first, url.isValidImageFile else {
            if let url = urls.first {
                logger.error("Invalid image file dropped: \(url.path)")
            }
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
        
        cleanupTempFiles()
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
    
    func importToCalendar(selectedEventIds: Set<String> = []) {
        Task {
            await MainActor.run {
                importStatus = .importing
                LoadingManager.shared.show(.processing)
            }
            
            do {
                guard try await calendarManager.requestAccess() else {
                    throw CalendarError.accessDenied
                }
                
                // 筛选要导入的事件
                let eventsToImport = selectedEventIds.isEmpty 
                    ? parsedEvents 
                    : parsedEvents.filter { selectedEventIds.contains($0.eventIdentifier) }
                
                // 导入事件
                var lastEventId: String?
                for event in eventsToImport {
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
                try? await Task.sleep(for: .seconds(2))
                await MainActor.run { resetState() }
            }
        }
    }
    
    func updateEvent(_ updatedEvent: CalendarEvent) {
        guard let index = parsedEvents.firstIndex(where: { $0.eventIdentifier == updatedEvent.eventIdentifier }) else {
            return
        }
        
        logger.info("Updating event: \(updatedEvent.title), \(updatedEvent.startDate)")
        parsedEvents[index] = updatedEvent
        
        NotificationCenter.default.post(
            name: .eventDidUpdate,
            object: nil,
            userInfo: ["event": updatedEvent]
        )
    }
}

// MARK: - Toast Management
extension AddScheduleViewModel {
    /// 显示Toast消息
    /// - Parameters:
    ///   - message: 消息内容
    ///   - type: Toast类型
    ///   - duration: 显示时长
    ///   - position: Toast位置，默认为中央
    func showToastMessage(
        _ message: String, 
        type: ToastType = .error, 
        duration: TimeInterval = 3.0,
        position: ToastPosition = .center
    ) {
        Task { @MainActor in
            // 重置现有toast
            showToast = false
            try? await Task.sleep(for: .milliseconds(300))
            
            // 显示新toast
            toastType = type
            toastMessage = message
            showToast = true
            
            // 延时隐藏
            try? await Task.sleep(for: .seconds(duration))
            
            // 如果仍然是同一个消息，则隐藏
            if toastMessage == message {
                showToast = false
            }
        }
    }
    
    /// 隐藏所有Toast
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
        logger.info("Image picker result: \(result)")
        
        switch result {
        case .success(let urls):
            guard let url = urls.first else {
                logger.error("No image selected")
                showToastMessage(NSLocalizedString("no_image_selected", comment: ""))
                return
            }
            
            // 安全访问 URL
            let startedAccessing = url.startAccessingSecurityScopedResource()
            defer { 
                if startedAccessing { url.stopAccessingSecurityScopedResource() }
            }
            
            do {
                let tempURL = try createTempCopy(of: url)
                handleDropped([tempURL])
            } catch {
                logger.error("Failed to create temp copy: \(error.localizedDescription)")
                showToastMessage(NSLocalizedString("image_access_failed", comment: ""))
            }
            
        case .failure(let error):
            logger.error("Image selection failed: \(error.localizedDescription)")
            showToastMessage(NSLocalizedString("image_selection_failed", comment: ""))
        }
    }
    
    /// 创建文件的临时副本
    private func createTempCopy(of url: URL) throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = url.lastPathComponent
        let tempURL = tempDir.appendingPathComponent(UUID().uuidString + "_" + fileName)
        
        // 复制文件到临时目录
        try FileManager.default.copyItem(at: url, to: tempURL)
        logger.info("Created temporary copy at: \(tempURL.path)")
        
        // 添加到临时文件列表以便后续清理
        tempImageURLs.append(tempURL)
        
        return tempURL
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
            return NSLocalizedString("calendar.error.access_denied", comment: "")
        }
    }
}

// MARK: - Manual Input Processing
extension AddScheduleViewModel {
    func processManualInput(_ text: String) async throws -> [CalendarEvent] {
        try await llmProcessor.processContent(text)
    }
}

// 假设 LoadingManager 的扩展，添加一个便捷方法来切换显示状态
private extension LoadingManager {
    func toggle(show: Bool, type: LoadingType) {
        if show { 
            self.show(type) 
        } else { 
            self.hide() 
        }
    }
}

// MARK: - Voice Recognition
extension AddScheduleViewModel {
    /// 设置语音识别相关的处理器和回调
    private func setupVoiceRecognition() {
        // 设置音频电平变化回调
        voiceRecognitionService.onLevelChanged = { [weak self] level in
            self?.audioLevel = level
        }
        
        // 设置状态变化回调
        voiceRecognitionService.onStateChanged = { [weak self] state in
            guard let self = self else { return }
            
            self.isRecording = state.isActiveRecording
            
            // 处理识别结果
            if case .success(let text) = state, !text.isEmpty {
                self.transcribedText = text
                self.logger.info("Voice recognition completed with \(text.count) characters")
            } else if case .failure(let error) = state {
                self.logger.error("Voice recognition failed: \(error.localizedDescription)")
                self.showToastMessage(error.localizedDescription, type: .error)
            }
        }
    }
    
    /// 开始语音识别
    func startVoiceRecognition() {
        logger.info("Preparing to start voice recognition")
        
        // 避免重复启动
        guard !isRecording else {
            logger.debug("Voice recognition already in progress, ignoring request")
            return
        }
        
        // 请求权限并启动语音识别
        Task {
            do {
                // 请求麦克风权限
                guard await requestMicrophonePermission() else {
                    logger.notice("Microphone access denied")
                    await MainActor.run {
                        showToastMessage(NSLocalizedString("microphone_access_denied", comment: ""), type: .error)
                    }
                    return
                }
                
                // 开始录音和识别
                logger.info("All permissions granted, starting voice recognition")
                startVoiceRecognitionSession()
            } catch {
                logger.error("Error starting voice recognition: \(error.localizedDescription)")
                await MainActor.run {
                    showToastMessage(error.localizedDescription, type: .error)
                }
            }
        }
    }
    
    /// 请求麦克风权限
    /// - Returns: 是否获得权限
    private func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            voiceRecognitionService.requestMicrophoneAccess { granted in
                continuation.resume(returning: granted)
            }
        }
    }
    
    /// 停止语音识别
    func stopVoiceRecognition() {
        logger.info("Stopping voice recognition")
        
        // 避免重复停止
        guard isRecording else {
            logger.debug("Voice recognition not active, ignoring stop request")
            return
        }
        
        Task {
            do {
                let recognizedText = try await voiceRecognitionService.stopRecordingAndRecognize()
                
                if !recognizedText.isEmpty {
                    await MainActor.run {
                        self.transcribedText = recognizedText
                        // 发送通知确保UI更新
                        NotificationCenter.default.post(
                            name: Notification.Name("voiceRecognitionCompleted"),
                            object: nil,
                            userInfo: ["text": recognizedText]
                        )
                    }
                    logger.info("Recognition completed with text of length: \(recognizedText.count)")
                }
            } catch {
                logger.error("Failed to recognize voice: \(error.localizedDescription)")
                await MainActor.run {
                    showToastMessage(error.localizedDescription, type: .error)
                }
            }
        }
    }
    
    /// 启动语音识别会话
    private func startVoiceRecognitionSession() {
        // 先重置状态，确保可以开始新的录制
        if let resetableService = voiceRecognitionService as? VoiceRecognitionService {
            resetableService.resetState()
        }
        
        if !voiceRecognitionService.startRecording() {
            logger.error("Failed to start recording session")
            showToastMessage(NSLocalizedString("recording_start_failed", comment: ""), type: .error)
        }
    }
}

// 扩展VoiceRecognitionState以简化状态判断
private extension VoiceRecognitionState {
    /// 是否为活跃录制状态
    var isActiveRecording: Bool {
        if case .recording = self {
            return true
        }
        return false
    }
}

import SwiftUI

// MARK: - PopoverViewModel
class PopoverViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var showEventList = false
    @Published var isDragging = false
    @Published var dragAnimation: DragAnimation = .none
    @Published var isOCRProcessing = false
    @Published var showUpgradeSheet = false
    @Published private(set) var canImport = false
    @Published private(set) var proStatus: ProStatus
    @Published var llmResponse: String = ""
    @Published var isLLMProcessing = false
    
    // MARK: - Private Properties
    private let processor = OCRProcessor()
    private let clipboardManager = ClipboardManager()
    private let webExtractor = WebContentExtractor()
    private let imageFetcher = ImageFetcher()
    private let llmService = LLMService.shared
    private let minimumLoadingDuration: TimeInterval = 1.2
    private var loadingStartTime: Date?
    
    // MARK: - Initialization
    init(proStatus: ProStatus = .free(remainingUses: 12)) {
        self.proStatus = proStatus
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
            print("📋 剪贴板为空或内容无效")
            return
        }
        
        switch content {
        case .url(let url): handleURLContent(url)
        case .image(let url): handleImageContent(url)
        }
    }
    
    private func handleURLContent(_ url: URL) {
        guard url.isValidWebURL else {
            print("⚠️ 无效的 URL 格式: \(url)")
            return
        }
        
        Task {
            await MainActor.run { LoadingManager.shared.show(.processing) }
            
            do {
                if try await URLHeaderInspector.shared.isImageURL(url) {
                    await handleImageURL(url)
                } else if try await URLHeaderInspector.shared.isHTMLPage(url) {
                    await handleWebContent(url)
                } else {
                    await updateState(loading: false, canImport: false)
                }
            } catch {
                await handleError(error)
            }
        }
    }
}

// MARK: - Content Processing
extension PopoverViewModel {
    private func handleImageContent(_ url: URL) {
        guard url.isValidImageFile else {
            print("⚠️ 无效的图片文件")
            return
        }
        
        Task {
            await startOCRProcessing()
            
            do {
                let results = try await processor.process(imagePath: url.path) { progress in
                    print("OCR Progress: \(progress * 100)%")
                }
                
                await completeOCRProcessing(with: results)
            } catch {
                await handleError(error)
            }
            
            try? FileManager.default.removeItem(atPath: url.path)
        }
    }
    
    private func handleWebContent(_ url: URL) async {
        do {
            let content = try await webExtractor.extract(from: url)
            print("🌐 网页内容: \(content.mainContent)")
            
            await MainActor.run { 
                isLLMProcessing = true
                LoadingManager.shared.show(.processing) 
            }
            
            // 构建提示语
            let prompt = "你好，杭州"
            
            // 调用 LLM 服务
            let response = try await llmService.chat(content: prompt)
            print("🤖 LLM 响应: \(response.content)")
            
            await MainActor.run {
                llmResponse = response.content
                isLLMProcessing = false
                LoadingManager.shared.hide()
                canImport = true
            }
        } catch {
            await handleError(error)
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
        print("❌ 处理失败: \(error.localizedDescription)")
        await updateState(loading: false, canImport: false)
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
        checkClipboardContent()
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

import SwiftUI

class PopoverViewModel: ObservableObject {
    @Published var showEventList: Bool = false
    @Published var isDragging: Bool = false
    @Published var dragAnimation: DragAnimation = .none
    @Published var isOCRProcessing: Bool = false
    @Published private(set) var canImport: Bool = false
    
    private let clipboardManager = ClipboardManager()
    private let minimumLoadingDuration: TimeInterval = 1.2  // 最小加载时间
    private var loadingStartTime: Date?
    
    enum DragAnimation {
        case none
        case pulse
        case bounce
        case glow
        case scale
        
        var animation: Animation {
            switch self {
            case .none:
                return .default
            case .pulse:
                return Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)
            case .bounce:
                return Animation.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0.3)
            case .glow:
                return Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true)
            case .scale:
                return Animation.easeInOut(duration: 0.5)
            }
        }
    }
    
    func checkClipboardContent() {
        if let content = clipboardManager.checkClipboard() {
            print(content.description)
        }
    }
    
    func resetState() {
        showEventList = false
        isDragging = false
        dragAnimation = .none
        isOCRProcessing = false
        canImport = false
        checkClipboardContent()
    }
    
    func handleDragEntered() {
        print("🔵 ViewModel - handleDragEntered")
        isDragging = true
        dragAnimation = .glow
    }
    
    func handleDragExited() {
        print("🔵 ViewModel - handleDragExited")
        isDragging = false
        dragAnimation = .none
    }
    
    func handleDropped(_ urls: [URL]) {
        guard let url = urls.first else { return }
        
        // 记录开始时间
        loadingStartTime = Date()
        
        // 显示加载状态
        isOCRProcessing = true
        LoadingManager.shared.show(.ocr)
        
        // 处理拖拽状态
        isDragging = false
        dragAnimation = .none
        
        // 处理图片
        processDroppedImage(at: url.path)
    }
    
    private func processDroppedImage(at path: String) {
        let ocrService = OCRService()
        
        ocrService.recognizeText(
            from: path,
            preferredLanguages: [.chinese, .english, .japanese]
        ) { [weak self] result in
            guard let self = self else { return }
            
            // 计算已经过的时间
            let elapsedTime = Date().timeIntervalSince(self.loadingStartTime ?? Date())
            
            // 如果处理时间太短，添加延迟
            let additionalDelay = max(0, self.minimumLoadingDuration - elapsedTime)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + additionalDelay) {
                // 隐藏加载状态
                self.isOCRProcessing = false
                LoadingManager.shared.hide()
                
                // 处理结果
                switch result {
                case .success(let results):
                    // 过滤出可靠的结果
                    let reliableResults = results.filter { $0.isReliable }
                    print("识别到 \(reliableResults.count) 条可靠文本")
                    
                    // 启用导入按钮
                    if !reliableResults.isEmpty {
                        self.canImport = true
                    }
                    
                case .failure(let error):
                    print("OCR 识别失败: \(error.localizedDescription)")
                    self.canImport = false
                }
            }
        }
    }
} 
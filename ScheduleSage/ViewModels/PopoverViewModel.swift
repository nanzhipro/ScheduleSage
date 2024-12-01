import SwiftUI

class PopoverViewModel: ObservableObject {
    @Published var showEventList: Bool = false
    @Published var isDragging: Bool = false
    @Published var dragAnimation: DragAnimation = .none
    @Published var isOCRProcessing: Bool = false
    @Published private(set) var canImport: Bool = false
    
    private let clipboardManager = ClipboardManager()
    private let webExtractor = WebContentExtractor()
    private let minimumLoadingDuration: TimeInterval = 1.2  // 最小加载时间
    private var loadingStartTime: Date?
    
    private let imageFetcher = ImageFetcher()
    
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
            switch content {
            case .url(let url):
                // 检查是否是图片 URL
                if url.absoluteString.isImageURL {
                    handleImageURL(url)
                } else {
                    handleURLContent(url)
                }
            case .image(let url):
                print("检测到图片: \(url.path)")
            }
        }
    }
    
    private func handleURLContent(_ url: URL) {
        // 显示加载状态
        LoadingManager.shared.show(.processing)
        
        Task {
            do {
                let content = try await webExtractor.extract(from: url)
                
                // 打印提取的内容
                print("🔵 URL Content Extracted:")
                print("----------------------------------------")
                print("标题: \(content.title)")
                print("----------------------------------------")
                print("描述: \(content.metadata.description ?? "无")")
                print("----------------------------------------")
                print("关键词: \(content.metadata.keywords.joined(separator: ", "))")
                print("----------------------------------------")
                print("主要内容:")
                print(content.mainContent)
                print("----------------------------------------")
                
                // 更新 UI 状态
                DispatchQueue.main.async {
                    LoadingManager.shared.hide()
                    self.canImport = true
                }
                
            } catch {
                print("🔴 URL 内容提取失败: \(error.localizedDescription)")
                
                // 更新 UI 状态
                DispatchQueue.main.async {
                    LoadingManager.shared.hide()
                    self.canImport = false
                }
            }
        }
    }
    
    private func handleImageURL(_ url: URL) {
        // 显示加载状态
        LoadingManager.shared.show(.network)
        
        Task {
            do {
                // 下载图片
                let imagePath = try await imageFetcher.fetchImage(from: url)
                print("🟢 图片下载成功: \(imagePath)")
                
                // 记录开始时间
                loadingStartTime = Date()
                
                // 更新状态为 OCR 处理
                await MainActor.run {
                    LoadingManager.shared.show(.ocr)
                    isOCRProcessing = true
                }
                
                // 执行 OCR 识别
                await performOCRProcessing(at: imagePath)
                
            } catch {
                print("🔴 图片下载失败: \(error.localizedDescription)")
                
                await MainActor.run {
                    LoadingManager.shared.hide()
                    isOCRProcessing = false
                    canImport = false
                }
            }
        }
    }
    
    private func performOCRProcessing(at path: String) async {
        let ocrService = OCRService()
        
        return await withCheckedContinuation { continuation in
            ocrService.recognizeText(
                from: path,
                preferredLanguages: [.chinese, .english, .japanese]
            ) { [weak self] result in
                guard let self = self else {
                    continuation.resume()
                    return
                }
                
                // 计算已经过的时间
                let elapsedTime = Date().timeIntervalSince(self.loadingStartTime ?? Date())
                let additionalDelay = max(0, self.minimumLoadingDuration - elapsedTime)
                
                // 延迟处理结果
                DispatchQueue.main.asyncAfter(deadline: .now() + additionalDelay) {
                    // 隐藏加载状态
                    self.isOCRProcessing = false
                    LoadingManager.shared.hide()
                    
                    // 处理结果
                    switch result {
                    case .success(let results):
                        // 按语言分组输出结果
                        let groupedResults = Dictionary(grouping: results) { $0.language }
                        
                        print("\n🟢 OCR 识别完成")
                        print("----------------------------------------")
                        
                        // 按语言输出
                        for (language, languageResults) in groupedResults {
                            print("📝 语言: \(language.rawValue)")
                            print("----------------------------------------")
                            
                            // 按置信度排序
                            let sortedResults = languageResults
                                .filter { $0.isReliable }
                                .sorted { $0.confidence > $1.confidence }
                            
                            // 输出文本
                            for result in sortedResults {
                                print("文本: \(result.text)")
                                print("置信度: \(String(format: "%.2f", result.confidence))")
                                if let box = result.boundingBox {
                                    print("位置: \(box)")
                                }
                                print("----------------------------------------")
                            }
                            
                            // 输出统计
                            print("可靠文本数量: \(sortedResults.count)")
                            print("平均置信度: \(String(format: "%.2f", sortedResults.map { $0.confidence }.reduce(0, +) / Float(sortedResults.count)))")
                            print("----------------------------------------\n")
                        }
                        
                        // 更新 UI 状态
                        self.canImport = !results.filter { $0.isReliable }.isEmpty
                        
                    case .failure(let error):
                        print("🔴 OCR 识别失败: \(error.localizedDescription)")
                        self.canImport = false
                    }
                    
                    continuation.resume()
                }
            }
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

// MARK: - Helper Extensions
private extension String {
    var isImageURL: Bool {
        let imageExtensions = ["jpg", "jpeg", "png", "gif", "heic"]
        let pathExtension = (self as NSString).pathExtension.lowercased()
        return imageExtensions.contains(pathExtension)
    }
} 
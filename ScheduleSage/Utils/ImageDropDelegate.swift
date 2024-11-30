import SwiftUI
import UniformTypeIdentifiers

struct ImageDropDelegate: DropDelegate {
    let onDrop: ([URL]) -> Void
    let onEntered: () -> Void
    let onExited: () -> Void
    let onOCRStateChange: (Bool) -> Void
    
    private let ocrService: OCRServiceProtocol
    
    init(
        onDrop: @escaping ([URL]) -> Void,
        onEntered: @escaping () -> Void,
        onExited: @escaping () -> Void,
        onOCRStateChange: @escaping (Bool) -> Void,
        ocrService: OCRServiceProtocol = OCRService()
    ) {
        self.onDrop = onDrop
        self.onEntered = onEntered
        self.onExited = onExited
        self.onOCRStateChange = onOCRStateChange
        self.ocrService = ocrService
    }
    
    // 支持的图片类型
    private let supportedTypes = [
        UTType.jpeg,
        UTType.png,
        UTType.gif,
        UTType.heic
    ]
    
    private func processImageWithOCR(at path: String) {
        print("🔵 OCR - Starting text recognition for image at: \(path)")
        
        // 显示加载指示器
        LoadingManager.shared.show(.ocr)
        
        ocrService.recognizeText(
            from: path,
            preferredLanguages: [.chinese, .english, .japanese]
        ) { result in
            DispatchQueue.main.async {
                // 隐藏加载指示器
                LoadingManager.shared.hide()
                
                switch result {
                case .success(let ocrResults):
                    print("🟢 OCR - Recognition completed")
                    print("🟢 OCR - Detected text:")
                    print("----------------------------------------")
                    
                    // 按语言分组结果
                    let groupedResults = Dictionary(grouping: ocrResults) { $0.language }
                    
                    // 按语言输出
                    for (language, results) in groupedResults {
                        print("📝 Language: \(language.rawValue)")
                        print("----------------------------------------")
                        
                        // 合并同一语言的文本，按置信度排序
                        let sortedResults = results.sorted { $0.confidence > $1.confidence }
                        for result in sortedResults {
                            print(result.text)
                        }
                        print("----------------------------------------\n")
                    }
                    
                    // 输出完整文本
                    print("📄 Complete Text:")
                    print("----------------------------------------")
                    let allText = ocrResults
                        .sorted { $0.confidence > $1.confidence }
                        .map { $0.text }
                        .joined(separator: " ")
                    print(allText)
                    print("----------------------------------------")
                    
                case .failure(let error):
                    print("🔴 OCR - Recognition failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func performDrop(info: DropInfo) -> Bool {
        print("🔵 ImageDropDelegate - performDrop started")
        
        // 获取所有拖拽项
        let providers = info.itemProviders(for: [.fileURL])
        print("🔵 ImageDropDelegate - Found \(providers.count) providers")
        
        for provider in providers {
            print("🔵 ImageDropDelegate - Processing provider: \(provider)")
            
            // 检查是否是文件 URL
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                print("🔵 ImageDropDelegate - Provider has file URL")
                
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
                    if let error = error {
                        print("🔴 ImageDropDelegate - Error loading item: \(error)")
                        return
                    }
                    
                    guard let urlData = item as? Data,
                          let url = URL(dataRepresentation: urlData, relativeTo: nil) else {
                        print("🔴 ImageDropDelegate - Failed to get URL from item")
                        return
                    }
                    
                    // 检查文件扩展名
                    let fileExtension = url.pathExtension.lowercased()
                    print("🔵 ImageDropDelegate - File extension: \(fileExtension)")
                    
                    // 验证是否是支持的图片类型
                    if ["jpg", "jpeg", "png", "gif", "heic"].contains(fileExtension) {
                        print("🟢 ImageDropDelegate - Successfully got image URL: \(url.path)")
                        
                        // 执行 OCR
                        processImageWithOCR(at: url.path)
                        
                        DispatchQueue.main.async {
                            print("🟢 ImageDropDelegate - Calling onDrop with URL")
                            onDrop([url])
                        }
                    } else {
                        print("🔴 ImageDropDelegate - Unsupported file type: \(fileExtension)")
                    }
                }
                return true
            } else {
                print("🔴 ImageDropDelegate - Provider does not have file URL")
            }
        }
        
        print("🔴 ImageDropDelegate - No valid providers found")
        return false
    }
    
    func validateDrop(info: DropInfo) -> Bool {
        let isValid = info.hasItemsConforming(to: [.fileURL])
        print("🔵 ImageDropDelegate - validateDrop: \(isValid)")
        return isValid
    }
    
    func dropEntered(info: DropInfo) {
        print("🔵 ImageDropDelegate - dropEntered")
        onEntered()
    }
    
    func dropExited(info: DropInfo) {
        print("🔵 ImageDropDelegate - dropExited")
        onExited()
    }
}

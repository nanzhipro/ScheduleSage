import SwiftUI
import UniformTypeIdentifiers

struct ImageDropDelegate: DropDelegate {
    let onDrop: ([URL]) -> Void
    let onEntered: () -> Void
    let onExited: () -> Void
    let onOCRStateChange: (Bool) -> Void
    
    private let processor: OCRProcessor
    
    init(
        onDrop: @escaping ([URL]) -> Void,
        onEntered: @escaping () -> Void,
        onExited: @escaping () -> Void,
        onOCRStateChange: @escaping (Bool) -> Void,
        processor: OCRProcessor = OCRProcessor()
    ) {
        self.onDrop = onDrop
        self.onEntered = onEntered
        self.onExited = onExited
        self.onOCRStateChange = onOCRStateChange
        self.processor = processor
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
        
        processor.processWithCallback(
            imagePath: path,
            onStateChange: { isProcessing in
                DispatchQueue.main.async {
                    if !isProcessing {
                        LoadingManager.shared.hide()
                    }
                    onOCRStateChange(isProcessing)
                }
            },
            progressHandler: { progress in
                print("OCR Progress: \(progress * 100)%")
            }
        ) { result in
            switch result {
            case .success(let results):
                processor.printDetailedResults(results)
            case .failure(let error):
                print("🔴 OCR - Recognition failed: \(error.localizedDescription)")
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

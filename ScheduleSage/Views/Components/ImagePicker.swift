//
//  ImagePicker.swift
//  ScheduleSage
//
//  Created by 南朋友 on 2024/03/26.
//

import SwiftUI
import UniformTypeIdentifiers

struct ImagePicker {
    private let supportedTypes = [
        UTType.jpeg,
        UTType.png,
        UTType.gif,
        UTType.heic
    ]
    
    let onImageSelected: (URL) -> Void
    let onError: ((Error) -> Void)?
    
    private let processor: OCRProcessor
    
    init(
        onImageSelected: @escaping (URL) -> Void,
        onError: ((Error) -> Void)? = nil,
        processor: OCRProcessor = OCRProcessor()
    ) {
        self.onImageSelected = onImageSelected
        self.onError = onError
        self.processor = processor
    }
    
    func showPicker() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = supportedTypes
        panel.title = NSLocalizedString("select_image", comment: "")
        panel.message = NSLocalizedString("select_image_message", comment: "")
        
        // 设置面板层级为最顶层
        panel.level = .floating
        
        // 如果有主窗口，设置为模态显示
        if let window = NSApp.mainWindow {
            panel.beginSheetModal(for: window) { response in
                if response == .OK, let url = panel.url {
                    handleSelectedImage(url)
                }
            }
        } else {
            // 如果没有主窗口，直接显示
            panel.begin { response in
                if response == .OK, let url = panel.url {
                    handleSelectedImage(url)
                }
            }
        }
    }
    
    private func handleSelectedImage(_ url: URL) {
        // 首先通知选择完成
        onImageSelected(url)
        
        print("开始处理选中的图片: \(url.path)")
        
        processor.processWithCallback(
            imagePath: url.path,
            progressHandler: { progress in
                print("OCR Progress: \(progress * 100)%")
            }
        ) { result in
            switch result {
            case .success(let results):
                print("✅ OCR 识别成功:")
                results.forEach { result in
                    print("文本: \(result.text)")
                    print("置信度: \(result.confidence)")
                    print("语言: \(result.language)")
                    print("---")
                }
                
            case .failure(let error):
                print("❌ OCR 识别失败: \(error.localizedDescription)")
                onError?(error)
            }
        }
    }
} 
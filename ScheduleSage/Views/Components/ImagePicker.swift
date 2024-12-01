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
        
        // 然后进行 OCR 处理
        let ocrService = OCRService()
        
        print("开始处理选中的图片: \(url.path)")
        
        ocrService.recognizeText(
            from: url.path,
            preferredLanguages: [.chinese, .english, .japanese]
        ) { result in
            switch result {
            case .success(let ocrResults):
                print("✅ OCR 识别成功:")
                ocrResults.forEach { result in
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
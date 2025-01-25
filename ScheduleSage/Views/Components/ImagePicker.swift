//
//  ImagePicker.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024/03/26.
//

import SwiftUI
import UniformTypeIdentifiers
import QuestOCR

// 图片选择器组件，负责图片选择和OCR处理
// Image picker component, responsible for image selection and OCR processing
struct ImagePicker {
    typealias ImageHandler = (URL) -> Void
    typealias ErrorHandler = (Error) -> Void
    
    private let supportedTypes = ImageSupport.supportedUTTypes
    private let processor: OCRProcessor
    private let onImageSelected: ImageHandler
    private let onError: ErrorHandler?
    
    init(
        onImageSelected: @escaping ImageHandler,
        onError: ErrorHandler? = nil,
        processor: OCRProcessor = OCRProcessor()
    ) {
        self.onImageSelected = onImageSelected
        self.onError = onError
        self.processor = processor
    }
    
    func showPicker() {
        let panel = makeOpenPanel()
        presentPanel(panel)
    }
}

// MARK: - Private Helpers
private extension ImagePicker {
    func makeOpenPanel() -> NSOpenPanel {
        let panel = NSOpenPanel()
        panel.configure(
            allowsMultipleSelection: false,
            canChooseDirectories: false,
            canChooseFiles: true,
            allowedContentTypes: supportedTypes
        )
        return panel
    }
    
    func presentPanel(_ panel: NSOpenPanel) {
        if let window = NSApp.mainWindow {
            presentModalPanel(panel, window: window)
        } else {
            presentStandalonePanel(panel)
        }
    }
    
    func presentModalPanel(_ panel: NSOpenPanel, window: NSWindow) {
        panel.beginSheetModal(for: window) { response in
            handlePanelResponse(panel, response: response)
        }
    }
    
    func presentStandalonePanel(_ panel: NSOpenPanel) {
        panel.begin { response in
            handlePanelResponse(panel, response: response)
        }
    }
    
    func handlePanelResponse(_ panel: NSOpenPanel, response: NSApplication.ModalResponse) {
        guard response == .OK, let url = panel.url else { return }
        handleSelectedImage(url)
    }
    
    func handleSelectedImage(_ url: URL) {
        onImageSelected(url)
        processImage(at: url)
    }
    
    func processImage(at url: URL) {
        Task {
            do {
                let results = try await processor.process(
                    imagePath: url.path
                ) { progress in
                    print("OCR Progress: \(Int(progress * 100))%")
                }
                processor.printDetailedResults(results)
            } catch {
                onError?(error)
                print("OCR: Recognition failed - \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - NSOpenPanel Configuration
private extension NSOpenPanel {
    func configure(
        allowsMultipleSelection: Bool,
        canChooseDirectories: Bool,
        canChooseFiles: Bool,
        allowedContentTypes: [UTType]
    ) {
        self.allowsMultipleSelection = allowsMultipleSelection
        self.canChooseDirectories = canChooseDirectories
        self.canChooseFiles = canChooseFiles
        self.allowedContentTypes = allowedContentTypes
        self.title = NSLocalizedString("select_image", comment: "")
        self.message = NSLocalizedString("select_image_message", comment: "")
        self.level = .floating
    }
}

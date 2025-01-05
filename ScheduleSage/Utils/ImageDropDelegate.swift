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
  private let supportedTypes = ImageSupport.supportedUTTypes

  private func processImageWithOCR(at path: String) {
    print("OCR: Starting text recognition for image at: \(path)")

    // 显示加载指示器
    LoadingManager.shared.show(.ocr)

    Task {
      do {
        // 更新处理状态
        onOCRStateChange(true)

        let results = try await processor.process(
          imagePath: path,
          progressHandler: { progress in
            print("OCR Progress: \(progress * 100)%")
          }
        )

        processor.printDetailedResults(results)

      } catch {
        print("OCR: Recognition failed - \(error.localizedDescription)")
      }

      // 完成后更新状态
      DispatchQueue.main.async {
        LoadingManager.shared.hide()
        onOCRStateChange(false)
      }
    }
  }

  func performDrop(info: DropInfo) -> Bool {
    print("ImageDropDelegate: Starting performDrop")

    // 获取所有拖拽项
    let providers = info.itemProviders(for: [.fileURL])
    print("ImageDropDelegate: Found \(providers.count) providers")

    for provider in providers {
      print("ImageDropDelegate: Processing provider: \(provider)")

      // 检查是否是文件 URL
      if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
        print("ImageDropDelegate: Provider contains file URL")

        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
          if let error = error {
            print("ImageDropDelegate: Error loading item - \(error)")
            return
          }

          guard let urlData = item as? Data,
            let url = URL(dataRepresentation: urlData, relativeTo: nil)
          else {
            print("ImageDropDelegate: Failed to extract URL from item")
            return
          }

          // 检查文件扩展名
          let fileExtension = url.pathExtension.lowercased()
          print("ImageDropDelegate: File extension detected - \(fileExtension)")

          // 验证是否是支持的图片类型
          if ImageSupport.isSupported(extension: fileExtension) {
            print("ImageDropDelegate: Successfully obtained image URL - \(url.path)")

            // 执行 OCR
            processImageWithOCR(at: url.path)

            DispatchQueue.main.async {
              print("ImageDropDelegate: Initiating onDrop callback with URL")
              onDrop([url])
            }
          } else {
            print("ImageDropDelegate: Unsupported file type - \(fileExtension)")
          }
        }
        return true
      } else {
        print("ImageDropDelegate: Provider lacks file URL")
      }
    }

    print("ImageDropDelegate: No valid providers available")
    return false
  }

  func validateDrop(info: DropInfo) -> Bool {
    let isValid = info.hasItemsConforming(to: [.fileURL])
    print("ImageDropDelegate: Validation result - \(isValid)")
    return isValid
  }

  func dropEntered(info: DropInfo) {
    print("ImageDropDelegate: Drop entered")
    onEntered()
  }

  func dropExited(info: DropInfo) {
    print("ImageDropDelegate: Drop exited")
    onExited()
  }
}

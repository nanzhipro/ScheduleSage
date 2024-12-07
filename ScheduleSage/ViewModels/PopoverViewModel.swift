import SwiftUI

class PopoverViewModel: ObservableObject {
  @Published var showEventList: Bool = false
  @Published var isDragging: Bool = false
  @Published var dragAnimation: DragAnimation = .none
  @Published var isOCRProcessing: Bool = false
  @Published private(set) var canImport: Bool = false
  @Published private(set) var proStatus: ProStatus
  @Published var showUpgradeSheet = false

  private let processor = OCRProcessor()
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

  init(proStatus: ProStatus = .free(remainingUses: 12)) {
    self.proStatus = proStatus
  }

  func checkClipboardContent() {
    guard let content = clipboardManager.checkClipboard() else {
      print("📋 剪贴板为空或内容无效")
      return
    }

    switch content {
    case .url(let url):
      handleURLContent(url)
    case .image(let url):
      handleImageContent(url)
    }
  }

  private func handleURLContent(_ url: URL) {
    // 首先验证 URL 的有效性
    guard let scheme = url.scheme?.lowercased(),
      ["http", "https"].contains(scheme),
      !url.absoluteString.isEmpty
    else {
      print("⚠️ 无效的 URL 格式: \(url)")
      return
    }

    print("🔍 开始处理 URL: \(url)")

    Task {
      do {
        await MainActor.run {
          LoadingManager.shared.show(.processing)
        }

        if try await URLHeaderInspector.shared.isImageURL(url) {
          print("🖼 检测到图片 URL")
          await handleImageURL(url)
        } else if try await URLHeaderInspector.shared.isHTMLPage(url) {
          print("📄 检测到网页 URL")
          await handleWebContent(url)
        } else {
          print("⚠️ 不支持的 URL 类型")
          await MainActor.run {
            LoadingManager.shared.hide()
            canImport = false
          }
        }
      } catch {
        print("❌ URL 处理失败: \(error.localizedDescription)")
        await MainActor.run {
          LoadingManager.shared.hide()
          canImport = false
        }
      }
    }
  }

  private func handleImageContent(_ url: URL) {
    print("🖼 开始处理图片内容: \(url.path)")

    guard FileManager.default.fileExists(atPath: url.path),
      isValidImageExtension(url.pathExtension)
    else {
      print("⚠️ 无效的图片文件")
      return
    }

    // 确保在主线程更新 UI 状态
    Task { @MainActor in
      loadingStartTime = Date()
      isOCRProcessing = true
      LoadingManager.shared.show(.ocr)
    }

    Task {
      do {
        let results = try await processor.process(
          imagePath: url.path,
          progressHandler: { progress in
            print("OCR Progress: \(progress * 100)%")
          }
        )

        // 计算经过的时间和需要的额外延迟
        let elapsedTime = Date().timeIntervalSince(loadingStartTime ?? Date())
        let additionalDelay = max(0, minimumLoadingDuration - elapsedTime)

        // 使用额外延迟来更新 UI
        try await Task.sleep(nanoseconds: UInt64(additionalDelay * 1_000_000_000))

        // 在主线程更新 UI 状态
        await MainActor.run {
          isOCRProcessing = false
          LoadingManager.shared.hide()
          handleOCRResults(results)
        }

      } catch {
        print("❌ OCR 识别失败: \(error.localizedDescription)")
        
        // 在主线程更新错误状态
        await MainActor.run {
          isOCRProcessing = false
          LoadingManager.shared.hide()
          canImport = false
        }
      }

      // 清理临时文件
      do {
        try FileManager.default.removeItem(atPath: url.path)
      } catch {
        print("⚠️ 临时文件清理失败")
      }
    }
  }

  private func handleWebContent(_ url: URL) async {
    print("📄 开始提取网页内容: \(url)")

    do {
      let content = try await webExtractor.extract(from: url)
      print("✅ 网页内容提取成功")

      await MainActor.run {
        LoadingManager.shared.hide()
        canImport = true
      }
    } catch {
      print("❌ 网页内容提取失败: \(error.localizedDescription)")

      await MainActor.run {
        LoadingManager.shared.hide()
        canImport = false
      }
    }
  }

  private func handleImageURL(_ url: URL) async {
    await MainActor.run {
      LoadingManager.shared.show(.network)
    }

    do {
      let processor = OCRProcessor()
      let results = try await processor.process(
        imagePath: url.path,
        progressHandler: { progress in
          print("OCR Progress: \(progress * 100)%")
        }
      )

      await MainActor.run {
        // 处理识别结果
        handleOCRResults(results)
        LoadingManager.shared.hide()
        canImport = true
      }

    } catch {
      print("🔴 Image OCR failed: \(error.localizedDescription)")
      await MainActor.run {
        LoadingManager.shared.hide()
        canImport = false
      }
    }
  }

  private func handleOCRResults(_ results: [OCRLanguage: [OCRResult]]) {
    // 打印识别结果
    processor.printDetailedResults(results)

    // 获取所有文本
    let allTexts = processor.getAllTexts(from: results)
    print("总计识别文本数: \(allTexts.count)")

    // 检查是否有可用结果
    canImport = !allTexts.isEmpty
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
    isDragging = true
    dragAnimation = .glow
  }

  func handleDragExited() {
    isDragging = false
    dragAnimation = .none
  }

  func handleDropped(_ urls: [URL]) {
    guard let url = urls.first else { return }

    // 确保在主线程更新 UI 状态
    Task { @MainActor in
      loadingStartTime = Date()
      isOCRProcessing = true
      LoadingManager.shared.show(.ocr)

      isDragging = false
      dragAnimation = .none
    }

    handleImageContent(url)
  }

  func showUpgradeSheetAction() {
    showUpgradeSheet = true
  }

  func canPerformAction(_ action: ProFeature.Action) -> Bool {
    if proStatus.isPro { return true }

    switch action {
    case .ocr:
      return proStatus.remainingUses ?? 0 > 0
    case .export:
      return true  // 免费用户可以导出
    case .advanced:
      return false  // 高级功能需要 Pro
    }
  }
}

// MARK: - Helper Extensions
private extension String {
  var isImageURL: Bool {
    let pathExtension = (self as NSString).pathExtension
    return ImageSupport.isSupported(extension: pathExtension)
  }
}

// MARK: - Helper Methods
private func isValidImageExtension(_ extension: String) -> Bool {
  ImageSupport.isSupported(extension: `extension`)
}

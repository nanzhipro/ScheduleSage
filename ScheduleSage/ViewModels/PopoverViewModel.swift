import SwiftUI

class PopoverViewModel: ObservableObject {
  @Published var showEventList: Bool = false
  @Published var isDragging: Bool = false
  @Published var dragAnimation: DragAnimation = .none
  @Published var isOCRProcessing: Bool = false
  @Published private(set) var canImport: Bool = false
  @Published private(set) var proStatus: ProStatus
  @Published var showUpgradeSheet = false

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
    if let content = clipboardManager.checkClipboard() {
      switch content {
      case .url(let url):
        Task {
          do {
            if try await URLHeaderInspector.shared.isImageURL(url) {
              await handleImageURL(url)
            } else if try await URLHeaderInspector.shared.isHTMLPage(url) {
              await handleURLContent(url)
            } else {
              print("⚠️ 不支持的 URL 类型")
              await MainActor.run {
                LoadingManager.shared.hide()
                canImport = false
              }
            }
          } catch {
            print("⚠️ URL 处理失败")
            await MainActor.run {
              LoadingManager.shared.hide()
              canImport = false
            }
          }
        }
      case .image(let url):
        loadingStartTime = Date()
        isOCRProcessing = true
        LoadingManager.shared.show(.ocr)
        performOCRProcessing(at: url.path)
      }
    }
  }

  private func handleURLContent(_ url: URL) async {
    await MainActor.run {
      LoadingManager.shared.show(.processing)
    }

    do {
      let content = try await webExtractor.extract(from: url)
      print("📄 提取网页内容: \(content.mainContent)")

      await MainActor.run {
        LoadingManager.shared.hide()
        self.canImport = true
      }

    } catch {
      print("🔴 URL 内容提取失败: \(error.localizedDescription)")

      await MainActor.run {
        LoadingManager.shared.hide()
        self.canImport = false
      }
    }
  }

  private func handleImageURL(_ url: URL) async {
    await MainActor.run {
      LoadingManager.shared.show(.network)
    }

    do {
      let imagePath = try await imageFetcher.fetchImage(from: url)
      print("📥 图片已下载")

      loadingStartTime = Date()

      await MainActor.run {
        LoadingManager.shared.show(.ocr)
        isOCRProcessing = true
      }

      performOCRProcessing(at: imagePath)

    } catch {
      print("🔴 图片下载失败: \(error.localizedDescription)")

      await MainActor.run {
        LoadingManager.shared.hide()
        isOCRProcessing = false
        canImport = false
      }
    }
  }

  private func performOCRProcessing(at path: String) {
    let ocrService = OCRService()

    ocrService.recognizeText(
      from: path,
      preferredLanguages: [.chinese, .english, .japanese]
    ) { [weak self] result in
      guard let self = self else { return }

      let elapsedTime = Date().timeIntervalSince(self.loadingStartTime ?? Date())
      let additionalDelay = max(0, self.minimumLoadingDuration - elapsedTime)

      DispatchQueue.main.asyncAfter(deadline: .now() + additionalDelay) {
        self.isOCRProcessing = false
        LoadingManager.shared.hide()

        switch result {
        case .success(let results):
          // 打印识别结果
          print("\n📝 OCR 识别结果:")
          print("----------------------------------------")
          for result in results {
            print("[\(result.language.rawValue)] \(result.text) (置信度: \(String(format: "%.2f", result.confidence)))")
          }
          print("总计识别文本数: \(results.count)")
          print("----------------------------------------\n")

          // 过滤可靠结果
          let reliableResults = results.filter { $0.isReliable }
          self.canImport = !reliableResults.isEmpty

        case .failure(let error):
          print("🔴 OCR 识别失败: \(error.localizedDescription)")
          self.canImport = false
        }

        // 清理临时文件
        do {
          try FileManager.default.removeItem(atPath: path)
        } catch {
          print("⚠️ 临时文件清理失败")
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
    isDragging = true
    dragAnimation = .glow
  }

  func handleDragExited() {
    isDragging = false
    dragAnimation = .none
  }

  func handleDropped(_ urls: [URL]) {
    guard let url = urls.first else { return }

    loadingStartTime = Date()

    isOCRProcessing = true
    LoadingManager.shared.show(.ocr)

    isDragging = false
    dragAnimation = .none

    performOCRProcessing(at: url.path)
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
    let imageExtensions = ["jpg", "jpeg", "png", "gif", "heic"]
    let pathExtension = (self as NSString).pathExtension.lowercased()
    return imageExtensions.contains(pathExtension)
  }
}

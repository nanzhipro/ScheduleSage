import Foundation

public enum OCRError: Error {
  case imageLoadFailed
  case recognitionFailed(String)
  case invalidFilePath
  case processingFailed
  case serviceUnavailable
  case unsupportedLanguage
  case noTextDetected
  case unsupportedFormat(String)

  public var localizedDescription: String {
    switch self {
    case .imageLoadFailed:
      return "无法加载图片文件"
    case .recognitionFailed(let reason):
      return "文字识别失败: \(reason)"
    case .invalidFilePath:
      return "无效的文件路径"
    case .processingFailed:
      return "OCR处理失败"
    case .serviceUnavailable:
      return "OCR服务不可用"
    case .unsupportedFormat(let format):
      return "不支持的图片格式: \(format)"
    case .unsupportedLanguage:
      return "不支持的语言"
    case .noTextDetected:
      return "未检测到文字"
    }
  }
}

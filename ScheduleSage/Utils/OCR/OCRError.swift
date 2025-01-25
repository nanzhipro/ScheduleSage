import Foundation

public enum OCRError: Error {
  case imageLoadFailed
  case recognitionFailed(String)
  case unsupportedLanguage
  case invalidFilePath
  case preprocessingFailed
  case noTextDetected

  public var localizedDescription: String {
    switch self {
    case .imageLoadFailed:
      return "Failed to load image"
    case .recognitionFailed(let message):
      return "Recognition failed: \(message)"
    case .unsupportedLanguage:
      return "Unsupported language"
    case .invalidFilePath:
      return "Invalid file path"
    case .preprocessingFailed:
      return "Failed to preprocess image"
    case .noTextDetected:
      return "No text detected in image"
    }
  }
}

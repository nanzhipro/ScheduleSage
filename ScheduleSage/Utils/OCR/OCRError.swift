import Foundation

enum OCRError: Error {
    case imageLoadFailed
    case recognitionFailed(String)
    case unsupportedLanguage
    case invalidFilePath
    
    var localizedDescription: String {
        switch self {
        case .imageLoadFailed:
            return "Failed to load image"
        case .recognitionFailed(let message):
            return "Recognition failed: \(message)"
        case .unsupportedLanguage:
            return "Unsupported language"
        case .invalidFilePath:
            return "Invalid file path"
        }
    }
} 
import Foundation

enum OCRLanguage: String {
  case chinese = "zh-Hans"
  case english = "en"
  case japanese = "ja"

  var recognitionLanguages: [String] {
    switch self {
    case .chinese:
      return ["zh-Hans", "zh-Hant"]
    case .english:
      return ["en-US", "en-GB"]
    case .japanese:
      return ["ja-JP"]
    }
  }
}

import Foundation

public enum OCRLanguage: String, CaseIterable {
  case chinese = "zh-Hans"
  case english = "en"
  case japanese = "ja"

  public var recognitionLanguages: [String] {
    switch self {
    case .chinese:
      return ["zh-Hans", "zh-Hant"]
    case .english:
      return ["en-US", "en-GB"]
    case .japanese:
      return ["ja-JP"]
    }
  }
  
  public var displayName: String {
    switch self {
    case .chinese: return NSLocalizedString("language.chinese", comment: "Chinese language name")
    case .english: return NSLocalizedString("language.english", comment: "English language name")
    case .japanese: return NSLocalizedString("language.japanese", comment: "Japanese language name")
    }
  }
}

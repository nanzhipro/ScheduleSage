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
    case .chinese: return "简体中文"
    case .english: return "English"
    case .japanese: return "日本語"
    }
  }
}

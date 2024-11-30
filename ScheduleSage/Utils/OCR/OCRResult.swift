import Foundation

struct OCRResult {
    let text: String
    let confidence: Float
    let language: OCRLanguage
    let boundingBox: CGRect?
    
    var isReliable: Bool {
        confidence > 0.7 // 可配置的置信度阈值
    }
} 
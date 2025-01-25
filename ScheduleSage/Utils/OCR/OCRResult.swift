import Foundation

public struct OCRResult: Equatable, Hashable {
    public let text: String
    public let confidence: Float
    public let language: OCRLanguage
    public let boundingBox: CGRect?
    public let timestamp: Date
    
    public var isReliable: Bool {
        confidence > 0.7
    }
    
    public init(
        text: String,
        confidence: Float,
        language: OCRLanguage,
        boundingBox: CGRect?,
        timestamp: Date = Date()
    ) {
        self.text = text
        self.confidence = confidence
        self.language = language
        self.boundingBox = boundingBox
        self.timestamp = timestamp
    }
}

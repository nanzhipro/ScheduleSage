import AppKit
import Vision

// MARK: - OCR Service Protocol
protocol OCRServiceProtocol {
    func recognizeText(
        from imagePath: String,
        preferredLanguages: [OCRLanguage]
    ) async throws -> [OCRResult]
}

// MARK: - OCR Service Implementation
final class OCRService: OCRServiceProtocol {
    // MARK: - Properties
    private let minimumConfidence: Float = 0.3
    
    // MARK: - Public Methods
    func recognizeText(
        from imagePath: String,
        preferredLanguages: [OCRLanguage] = [.chinese, .english, .japanese]
    ) async throws -> [OCRResult] {
        // 加载图像
        guard let image = NSImage(contentsOfFile: imagePath),
              let cgImage = image.cgImage
        else {
            throw OCRError.imageLoadFailed
        }
        
        // 创建识别请求
        let request = createTextRecognitionRequest(languages: preferredLanguages)
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        // 执行识别
        try await handler.perform([request])
        
        // 处理结果
        guard let observations = request.results as? [VNRecognizedTextObservation] else {
            throw OCRError.recognitionFailed("Invalid observation results")
        }
        
        // 转换结果
        return observations.compactMap { observation in
            processObservation(observation)
        }
        .filter { $0.confidence >= minimumConfidence }
    }
    
    // MARK: - Private Methods
    private func createTextRecognitionRequest(
        languages: [OCRLanguage]
    ) -> VNRecognizeTextRequest {
        let request = VNRecognizeTextRequest()
        request.recognitionLanguages = languages.flatMap { $0.recognitionLanguages }
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        return request
    }
    
    private func processObservation(_ observation: VNRecognizedTextObservation) -> OCRResult? {
        guard let candidate = observation.topCandidates(1).first else { return nil }
        
        return OCRResult(
            text: candidate.string,
            confidence: candidate.confidence,
            language: detectLanguage(for: candidate.string),
            boundingBox: observation.boundingBox
        )
    }
    
    private func detectLanguage(for text: String) -> OCRLanguage {
        let tagger = NSLinguisticTagger(tagSchemes: [.language], options: 0)
        tagger.string = text
        
        return tagger.dominantLanguage.map { languageCode in
            switch languageCode {
            case "zh-Hans", "zh-Hant": return .chinese
            case "ja": return .japanese
            default: return .english
            }
        } ?? .english
    }
}

// MARK: - NSImage Extension
private extension NSImage {
    var cgImage: CGImage? {
        guard let imageData = tiffRepresentation,
              let imageSource = CGImageSourceCreateWithData(imageData as CFData, nil)
        else { return nil }
        
        return CGImageSourceCreateImageAtIndex(imageSource, 0, nil)
    }
}

import Foundation
import Vision

// MARK: - OCR Service Implementation
final class OCRService: OCRServiceProtocol {
    // MARK: - Properties
    var configuration: OCRConfiguration
    let supportedLanguages: [OCRLanguage] = OCRLanguage.allCases
    
    private var startTime: Date?
    private var lastMetrics: OCRMetrics?
    
    // MARK: - Initialization
    init(configuration: OCRConfiguration = .default) {
        self.configuration = configuration
    }
    
    // MARK: - Public Methods
    func recognizeText(
        from imagePath: String,
        preferredLanguages: [OCRLanguage] = []
    ) async throws -> [OCRResult] {
        startTime = Date()
        
        // 检查缓存
        if configuration.enableCache,
           let cachedResult = OCRCache.shared.retrieve(forKey: imagePath) {
            return [cachedResult]
        }
        
        // 加载图像
        guard let image = PlatformImage(contentsOfFile: imagePath),
              let cgImage = image.platformCGImage else {
            throw OCRError.imageLoadFailed
        }
        
        return try await recognizeText(from: image, cgImage: cgImage, preferredLanguages: preferredLanguages)
    }
    
    func recognizeText(
        from image: PlatformImage,
        preferredLanguages: [OCRLanguage] = []
    ) async throws -> [OCRResult] {
        startTime = Date()
        
        guard let cgImage = image.platformCGImage else {
            throw OCRError.imageLoadFailed
        }
        
        return try await recognizeText(from: image, cgImage: cgImage, preferredLanguages: preferredLanguages)
    }
    
    func collectMetrics() -> OCRMetrics? {
        return lastMetrics
    }
    
    // MARK: - Private Methods
    private func recognizeText(
        from image: PlatformImage,
        cgImage: CGImage,
        preferredLanguages: [OCRLanguage]
    ) async throws -> [OCRResult] {
        let languages = preferredLanguages.isEmpty ? configuration.preferredLanguages : preferredLanguages
        let request = createTextRecognitionRequest(languages: languages)
        
        try await performRecognition(cgImage: cgImage, request: request)
        
        guard let observations = request.results else {
            throw OCRError.recognitionFailed("No results available")
        }
        
        // 对观察结果进行排序，按从上到下、从左到右的阅读顺序
        // 注意：Vision框架中的坐标系原点在左下角，minY值较小的观察结果实际上在图片的上方
        // 因此，我们需要按minY降序排序，相同minY的按minX升序排序
        let sortedObservations = (observations as! [VNRecognizedTextObservation]).sorted { first, second in
            // 定义一个误差范围，用于确定两个文本行是否在同一水平线上
            let yThreshold: CGFloat = 0.03 // 调整此值以适应您的文本行间距
            
            // 如果两个观察结果在同一水平线上（y值相近）
            if abs(first.boundingBox.minY - second.boundingBox.minY) < yThreshold {
                // 从左到右排序（按minX升序）
                return first.boundingBox.minX < second.boundingBox.minX
            } else {
                // 从上到下排序（minY越大表示越靠上）
                return first.boundingBox.minY > second.boundingBox.minY
            }
        }
        
        let results = sortedObservations.compactMap { observation -> OCRResult? in
            return processObservation(observation)
        }
        
        let filteredResults = results.filter { $0.confidence >= configuration.minimumConfidence }
        
        guard !filteredResults.isEmpty else {
            throw OCRError.noTextDetected
        }
        
        updateMetrics(image: image, results: filteredResults)
        
        if configuration.enableCache, let firstResult = filteredResults.first {
            OCRCache.shared.store(firstResult, forKey: String(describing: image))
        }
        
        return filteredResults
    }
    
    private func performRecognition(
        cgImage: CGImage,
        request: VNRecognizeTextRequest
    ) async throws {
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            do {
                try handler.perform([request])
                continuation.resume()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
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
        observation.topCandidates(1).first.map { candidate in
            OCRResult(
                text: candidate.string,
                confidence: candidate.confidence,
                language: detectLanguage(for: candidate.string),
                boundingBox: observation.boundingBox,
                timestamp: Date()
            )
        }
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
    
    private func updateMetrics(image: PlatformImage, results: [OCRResult]) {
        guard let startTime = startTime else { return }
        
        let processingTime = Date().timeIntervalSince(startTime)
        let averageConfidence = Float(results.map(\.confidence).reduce(0, +)) / Float(results.count)
        let recognizedLanguages = Array(Set(results.map(\.language)))
        
        lastMetrics = OCRMetrics(
            processingTime: processingTime,
            imageSize: image.platformSize,
            recognizedLanguages: recognizedLanguages,
            confidence: averageConfidence
        )
    }
    
    /// 清理OCR服务使用的资源
    @MainActor
    func cleanup() {
        // 重置状态
        startTime = nil
        lastMetrics = nil
        
        // 清理缓存（如果需要）
        if configuration.enableCache {
            OCRCache.shared.clear()
        }
    }
}

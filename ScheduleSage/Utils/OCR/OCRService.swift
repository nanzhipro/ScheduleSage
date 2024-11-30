import Vision
import AppKit

protocol OCRServiceProtocol {
    func recognizeText(
        from imagePath: String,
        preferredLanguages: [OCRLanguage],
        completion: @escaping (Result<[OCRResult], OCRError>) -> Void
    )
}

class OCRService: OCRServiceProtocol {
    // MARK: - Properties
    private let minimumConfidence: Float = 0.3
    private let queue = DispatchQueue(label: "com.schedulesage.ocr", qos: .userInitiated)
    
    // MARK: - Public Methods
    func recognizeText(
        from imagePath: String,
        preferredLanguages: [OCRLanguage] = [.chinese, .english, .japanese],
        completion: @escaping (Result<[OCRResult], OCRError>) -> Void
    ) {
        queue.async {
            guard let image = NSImage(contentsOfFile: imagePath) else {
                completion(.failure(.imageLoadFailed))
                return
            }
            
            // 创建 Vision 请求
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    completion(.failure(.recognitionFailed(error.localizedDescription)))
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    completion(.failure(.recognitionFailed("Invalid observation results")))
                    return
                }
                
                let results = observations.compactMap { observation -> OCRResult? in
                    guard let candidate = observation.topCandidates(1).first else { return nil }
                    
                    // 检测语言
                    let language = self.detectLanguage(for: candidate.string)
                    
                    return OCRResult(
                        text: candidate.string,
                        confidence: candidate.confidence,
                        language: language,
                        boundingBox: observation.boundingBox
                    )
                }
                .filter { $0.confidence >= self.minimumConfidence }
                
                DispatchQueue.main.async {
                    completion(.success(results))
                }
            }
            
            // 配置识别请求
            request.recognitionLanguages = preferredLanguages.flatMap { $0.recognitionLanguages }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            // 创建图片处理请求
            guard let cgImage = self.convertToCGImage(from: image) else {
                completion(.failure(.imageLoadFailed))
                return
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                completion(.failure(.recognitionFailed(error.localizedDescription)))
            }
        }
    }
    
    // MARK: - Private Methods
    private func detectLanguage(for text: String) -> OCRLanguage {
        // 使用 NSLinguisticTagger 检测语言
        let tagger = NSLinguisticTagger(
            tagSchemes: [.language],
            options: 0
        )
        tagger.string = text
        guard let language = tagger.dominantLanguage else {
            return .english // 默认返回英语
        }
        
        switch language {
        case "zh-Hans", "zh-Hant":
            return .chinese
        case "ja":
            return .japanese
        default:
            return .english
        }
    }
    
    private func convertToCGImage(from nsImage: NSImage) -> CGImage? {
        guard let imageData = nsImage.tiffRepresentation,
              let imageSource = CGImageSourceCreateWithData(imageData as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil)
        else {
            return nil
        }
        return cgImage
    }
} 
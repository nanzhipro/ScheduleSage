//
//  OCRProcessor.swift
//  ScheduleSage
//
//  Created by 南朋友 on 2024-03-20.
//

import Foundation

// MARK: - OCR 处理器
public final class OCRProcessor {
    private let ocrService: OCRServiceProtocol
    private let minimumConfidence: Float
    
    init(
        minimumConfidence: Float = 0.7,
        ocrService: OCRServiceProtocol = OCRService()
    ) {
        self.minimumConfidence = minimumConfidence
        self.ocrService = ocrService
    }
    
    /// 处理图片并返回 OCR 结果
    /// - Parameters:
    ///   - imagePath: 图片文件的绝对路径
    ///   - languages: 需要识别的语言列表，默认支持中文、英文和日文
    ///   - progressHandler: 处理进度回调
    /// - Returns: 按语言分组的可靠 OCR 结果
    func process(
        imagePath: String,
        languages: [OCRLanguage] = [.chinese, .english, .japanese],
        progressHandler: ((Double) -> Void)? = nil
    ) async throws -> [OCRLanguage: [OCRResult]] {
        
        // 验证图片路径
        guard FileManager.default.fileExists(atPath: imagePath) else {
            throw OCRError.invalidFilePath
        }
        
        progressHandler?(0.2)
        
        return try await withCheckedThrowingContinuation { continuation in
            ocrService.recognizeText(
                from: imagePath,
                preferredLanguages: languages
            ) { result in
                progressHandler?(0.8)
                
                switch result {
                case .success(let results):
                    // 过滤并分组结果
                    let reliableResults = results.filter { $0.isReliable }
                    
                    guard !reliableResults.isEmpty else {
                        continuation.resume(throwing: OCRError.recognitionFailed("No reliable results"))
                        return
                    }
                    
                    // 按语言分组
                    let groupedResults = Dictionary(
                        grouping: reliableResults,
                        by: { $0.language }
                    )
                    
                    progressHandler?(1.0)
                    continuation.resume(returning: groupedResults)
                    
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// 获取指定语言的文��结果
    /// - Parameters:
    ///   - results: OCR 结果
    ///   - language: 目标语言
    /// - Returns: 该语言的所有文本内容
    func getTexts(from results: [OCRLanguage: [OCRResult]], for language: OCRLanguage) -> [String] {
        results[language]?.map { $0.text } ?? []
    }
    
    /// 获取所有语言的文本结果
    /// - Parameter results: OCR 结果
    /// - Returns: 所有识别出的文本内容
    func getAllTexts(from results: [OCRLanguage: [OCRResult]]) -> [String] {
        results.values.flatMap { $0.map { $0.text } }
    }
    
    /// 处理图片并直接返回可靠的文本结果
    /// - Parameters:
    ///   - imagePath: 图片路径
    ///   - languages: 支持的语言
    ///   - onStateChange: OCR 状态变化回调
    ///   - progressHandler: 进度回调
    ///   - completion: 完成回调，返回可靠的文本结果
    func processWithCallback(
        imagePath: String,
        languages: [OCRLanguage] = [.chinese, .english, .japanese],
        onStateChange: ((Bool) -> Void)? = nil,
        progressHandler: ((Double) -> Void)? = nil,
        completion: @escaping (Result<[OCRResult], Error>) -> Void
    ) {
        // 更新状态
        onStateChange?(true)
        progressHandler?(0.2)
        
        ocrService.recognizeText(
            from: imagePath,
            preferredLanguages: languages
        ) { result in
            progressHandler?(0.8)
            
            switch result {
            case .success(let results):
                let reliableResults = results.filter { $0.isReliable }
                completion(.success(reliableResults))
            case .failure(let error):
                completion(.failure(error))
            }
            
            progressHandler?(1.0)
            onStateChange?(false)
        }
    }
    
    /// 打印 OCR 结果的详细信息
    /// - Parameter results: OCR 结果
    func printDetailedResults(_ results: [OCRResult]) {
        print("🟢 OCR - Recognition completed")
        print("🟢 OCR - Detected text:")
        print("----------------------------------------")
        
        // 按语言分组结果
        let groupedResults = Dictionary(grouping: results) { $0.language }
        
        // 按语言输出
        for (language, results) in groupedResults {
            print("📝 Language: \(language.rawValue)")
            print("----------------------------------------")
            
            // 合并同一语言的文本，按置信度排序
            let sortedResults = results.sorted { $0.confidence > $1.confidence }
            for result in sortedResults {
                print(result.text)
            }
            print("----------------------------------------\n")
        }
        
        // 输出完整文本
        print("📄 Complete Text:")
        print("----------------------------------------")
        let allText = results
            .sorted { $0.confidence > $1.confidence }
            .map { $0.text }
            .joined(separator: " ")
        print(allText)
        print("----------------------------------------")
    }
}

// MARK: - 便利扩展
extension OCRProcessor {
    /// 快速处理单张图片
    static func quickProcess(
        imagePath: String,
        languages: [OCRLanguage] = [.chinese, .english, .japanese]
    ) async throws -> [String] {
        let processor = OCRProcessor()
        let results = try await processor.process(imagePath: imagePath, languages: languages)
        return processor.getAllTexts(from: results)
    }
} 
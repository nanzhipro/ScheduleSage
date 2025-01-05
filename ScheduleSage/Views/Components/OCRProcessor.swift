//
//  OCRProcessor.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-20.
//

import Foundation

// MARK: - OCR 处理器
final class OCRProcessor {
  private let ocrService: OCRServiceProtocol
  private let queue: DispatchQueue

  init(
    ocrService: OCRServiceProtocol = OCRService(),
    queue: DispatchQueue = DispatchQueue(label: "com.schedulesage.ocrprocessor", qos: .userInitiated)
  ) {
    self.ocrService = ocrService
    self.queue = queue
  }

  /// 处理图片并返回 OCR 结果
  /// - Parameters:
  ///   - imagePath: 图片文件的绝对路径
  ///   - languages: 需要识别的语言列表，默认支持中文、英文和日文
  ///   - progressHandler: 处理进度回调
  /// - Returns: 按语言分组的 OCR 结果
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
          // 按语言分组
          let groupedResults = Dictionary(
            grouping: results,
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

  /// 获取指定语言的文本结果
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
}

// MARK: - Debug Helpers
extension OCRProcessor {
  /// 打印 OCR 结果的详细信息
  /// - Parameter results: OCR 结果
  func printDetailedResults(_ results: [OCRLanguage: [OCRResult]]) {
    queue.async {
      print("OCR: Recognition completed successfully")
      print("----------------------------------------")

      for (language, languageResults) in results {
        print("OCR: Detected language - \(language.rawValue)")
        print("----------------------------------------")

        for result in languageResults.sorted(by: { $0.confidence > $1.confidence }) {
          print("Text: \(result.text)")
          print("Confidence: \(result.confidence)")
          print("----------------------------------------")
        }
      }
    }
  }
}

// MARK: - Convenience Methods
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

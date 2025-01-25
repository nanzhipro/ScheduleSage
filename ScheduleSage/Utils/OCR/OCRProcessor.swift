//
//  OCRProcessor.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-20.
//

import Foundation
import SwiftUI

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// MARK: - OCR Processing State
public enum OCRProcessingState {
    case idle
    case processing(progress: Double)
    case completed([OCRLanguage: [OCRResult]])
    case failed(Error)
    
    public var isProcessing: Bool {
        if case .processing = self { return true }
        return false
    }
}

// MARK: - OCR Processor Delegate
public protocol OCRProcessorDelegate: AnyObject {
    func ocrProcessor(_ processor: OCRProcessor, didUpdateProgress progress: Double)
    func ocrProcessor(_ processor: OCRProcessor, didCompleteWithResults results: [OCRLanguage: [OCRResult]])
    func ocrProcessor(_ processor: OCRProcessor, didFailWithError error: Error)
}

// MARK: - OCR Processor
public final class OCRProcessor: ObservableObject {
    // MARK: - Properties
    @Published public private(set) var state: OCRProcessingState = .idle
    @Published public private(set) var lastMetrics: OCRMetrics?
    
    public weak var delegate: OCRProcessorDelegate?
    
    private var service: OCRServiceProtocol
    private let queue: DispatchQueue
    
    // MARK: - Configuration
    public var configuration: OCRConfiguration {
        get { service.configuration }
        set { service.configuration = newValue }
    }
    
    public var supportedLanguages: [OCRLanguage] {
        service.supportedLanguages
    }
    
    // MARK: - Initialization
    public init(
        configuration: OCRConfiguration = .default,
        queue: DispatchQueue = DispatchQueue(label: "com.quest.ocrprocessor", qos: .userInitiated)
    ) {
        self.service = OCRService(configuration: configuration)
        self.queue = queue
    }
    
    // MARK: - Public Methods
    
    /// 处理图片文件
    /// - Parameters:
    ///   - imagePath: 图片文件路径
    ///   - languages: 需要识别的语言列表
    ///   - progressHandler: 进度回调
    /// - Returns: 按语言分组的识别结果
    public func process(
        imagePath: String,
        languages: [OCRLanguage] = [],
        progressHandler: ((Double) -> Void)? = nil
    ) async throws -> [OCRLanguage: [OCRResult]] {
        await updateState(.processing(progress: 0))
        
        do {
            // 验证图片路径
            guard FileManager.default.fileExists(atPath: imagePath) else {
                let error = OCRError.invalidFilePath
                await handleError(error)
                throw error
            }
            
            await updateProgress(0.2, progressHandler)
            
            // 执行 OCR 识别
            let results = try await service.recognizeText(
                from: imagePath,
                preferredLanguages: languages
            )
            
            await updateProgress(0.8, progressHandler)
            
            // 按语言分组
            let groupedResults = Dictionary(
                grouping: results,
                by: { $0.language }
            )
            
            await updateProgress(1.0, progressHandler)
            await handleSuccess(groupedResults)
            
            return groupedResults
        } catch {
            await handleError(error)
            throw error
        }
    }
    
    /// 处理图片
    /// - Parameters:
    ///   - image: 图片对象
    ///   - languages: 需要识别的语言列表
    ///   - progressHandler: 进度回调
    /// - Returns: 按语言分组的识别结果
    public func process(
        image: PlatformImage,
        languages: [OCRLanguage] = [],
        progressHandler: ((Double) -> Void)? = nil
    ) async throws -> [OCRLanguage: [OCRResult]] {
        await updateState(.processing(progress: 0))
        
        do {
            await updateProgress(0.2, progressHandler)
            
            // 执行 OCR 识别
            let results = try await service.recognizeText(
                from: image,
                preferredLanguages: languages
            )
            
            await updateProgress(0.8, progressHandler)
            
            // 按语言分组
            let groupedResults = Dictionary(
                grouping: results,
                by: { $0.language }
            )
            
            await updateProgress(1.0, progressHandler)
            await handleSuccess(groupedResults)
            
            return groupedResults
        } catch {
            await handleError(error)
            throw error
        }
    }
    
    /// 获取指定语言的文本结果
    public func getTexts(from results: [OCRLanguage: [OCRResult]], for language: OCRLanguage) -> [String] {
        results[language]?.map { $0.text } ?? []
    }
    
    /// 获取所有语言的文本结果
    public func getAllTexts(from results: [OCRLanguage: [OCRResult]]) -> [String] {
        results.values.flatMap { $0.map { $0.text } }
    }
    
    /// 获取性能指标
    public func getMetrics() -> OCRMetrics? {
        service.collectMetrics()
    }
    
    // MARK: - Private Methods
    @MainActor
    private func updateState(_ newState: OCRProcessingState) {
        state = newState
    }
    
    @MainActor
    private func updateProgress(_ progress: Double, _ handler: ((Double) -> Void)?) {
        state = .processing(progress: progress)
        handler?(progress)
        delegate?.ocrProcessor(self, didUpdateProgress: progress)
    }
    
    @MainActor
    private func handleSuccess(_ results: [OCRLanguage: [OCRResult]]) {
        state = .completed(results)
        delegate?.ocrProcessor(self, didCompleteWithResults: results)
        lastMetrics = service.collectMetrics()
    }
    
    @MainActor
    private func handleError(_ error: Error) {
        state = .failed(error)
        delegate?.ocrProcessor(self, didFailWithError: error)
    }
}

// MARK: - Debug Helpers
extension OCRProcessor {
    public func printDetailedResults(_ results: [OCRLanguage: [OCRResult]]) {
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
            
            if let metrics = self.getMetrics() {
                print("Processing Time: \(metrics.processingTime) seconds")
                print("Image Size: \(metrics.imageSize)")
                print("Average Confidence: \(metrics.confidence)")
                print("----------------------------------------")
            }
        }
    }
}

// MARK: - Convenience Methods
extension OCRProcessor {
    public static func quickProcess(
        imagePath: String,
        languages: [OCRLanguage] = []
    ) async throws -> [String] {
        let processor = OCRProcessor()
        let results = try await processor.process(imagePath: imagePath, languages: languages)
        return processor.getAllTexts(from: results)
    }
    
    public static func quickProcess(
        image: PlatformImage,
        languages: [OCRLanguage] = []
    ) async throws -> [String] {
        let processor = OCRProcessor()
        let results = try await processor.process(image: image, languages: languages)
        return processor.getAllTexts(from: results)
    }
}

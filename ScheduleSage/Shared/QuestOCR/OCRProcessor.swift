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
                let error = OCRError.imageLoadFailed
                await handleError(error)
                throw error
            }
            
            await updateProgress(0.1, progressHandler)
            
            // 检查文件格式并转换图片
            let image = try await convertToProcessableImage(fromPath: imagePath)
            
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
    
    /// 获取格式化的文本结果，保持OCR识别的视觉顺序
    /// - Parameter results: OCR识别结果
    /// - Returns: 格式化的文本字符串，包含换行符以保持文本布局
    public func getFormattedText(from results: [OCRLanguage: [OCRResult]]) -> String {
        // 合并所有语言的结果
        let allResults = results.values.flatMap { $0 }
        
        // 如果结果为空，直接返回空字符串
        if allResults.isEmpty {
            return ""
        }
        
        // 将所有结果按相对位置排序（虽然OCRService已经排序，但这里再次确保）
        let sortedResults = allResults.sorted { first, second in
            guard let firstBox = first.boundingBox, let secondBox = second.boundingBox else {
                return false
            }
            
            // 定义一个误差范围，用于确定两个文本行是否在同一水平线上
            let yThreshold: CGFloat = 0.03
            
            // 如果两个观察结果在同一水平线上（y值相近）
            if abs(firstBox.minY - secondBox.minY) < yThreshold {
                // 从左到右排序
                return firstBox.minX < secondBox.minX
            } else {
                // 从上到下排序
                return firstBox.minY > secondBox.minY
            }
        }
        
        // 检测何时需要添加换行符
        var formattedText = ""
        var previousY: CGFloat? = nil
        
        for result in sortedResults {
            guard let box = result.boundingBox else {
                if !formattedText.isEmpty {
                    formattedText += " "
                }
                formattedText += result.text
                continue
            }
            
            if let prevY = previousY, abs(prevY - box.minY) > 0.03 {
                // 不同的行，添加换行符
                formattedText += "\n"
            } else if !formattedText.isEmpty {
                // 同一行，添加空格
                formattedText += " "
            }
            
            formattedText += result.text
            previousY = box.minY
        }
        
        return formattedText
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
    
    /// 将不同格式的图片文件转换为可处理的图片对象
    /// - Parameter path: 图片文件路径
    /// - Returns: 平台相关的图片对象
    private func convertToProcessableImage(fromPath path: String) async throws -> PlatformImage {
        let url = URL(fileURLWithPath: path)
        let fileExtension = url.pathExtension.lowercased()
        
        // 处理WebP格式
        if fileExtension == "webp" {
            #if os(iOS) || os(macOS)
            // 使用ImageIO框架处理WebP
            let options = [kCGImageSourceShouldCache: true] as CFDictionary
            guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, options),
                  let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, options) else {
                
                // 如果直接加载失败，尝试先读取数据再处理
                do {
                    let data = try Data(contentsOf: url)
                    guard let imageSource = CGImageSourceCreateWithData(data as CFData, options),
                          let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, options) else {
                        throw OCRError.imageLoadFailed
                    }
                    
                    #if os(iOS)
                    return UIImage(cgImage: cgImage)
                    #elseif os(macOS)
                    return NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
                    #endif
                } catch {
                    throw OCRError.imageLoadFailed
                }
            }
                
            #if os(iOS)
            return UIImage(cgImage: cgImage)
            #elseif os(macOS)
            return NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
            #endif
            #else
            throw OCRError.imageLoadFailed
            #endif
        }
        
        // 处理常规图片格式
        #if os(iOS)
        guard let image = UIImage(contentsOfFile: path) else {
            throw OCRError.imageLoadFailed
        }
        return image
        #elseif os(macOS)
        // 尝试直接加载图片
        if let image = NSImage(contentsOfFile: path) {
            return image
        }
        
        // 如果直接加载失败，尝试通过数据加载
        do {
            let data = try Data(contentsOf: url)
            if let image = NSImage(data: data) {
                return image
            }
        } catch {
            // 继续尝试其他方法
        }
        
        // 最后尝试使用 ImageIO
        do {
            let options = [kCGImageSourceShouldCache: true] as CFDictionary
            guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, options),
                  let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, options) else {
                throw OCRError.imageLoadFailed
            }
            return NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        } catch {
            throw OCRError.imageLoadFailed
        }
        #else
        throw OCRError.imageLoadFailed
        #endif
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
    
    /// 清理资源，包括图像缓存和处理状态
    @MainActor
    public func cleanup() {
        // 清理OCR服务资源
        service.cleanup()
        
        // 重置状态
        state = .idle
        lastMetrics = nil
    }
}

// MARK: - Debug Helpers
extension OCRProcessor {
    public func printDetailedResults(_ results: [OCRLanguage: [OCRResult]]) {
        queue.async {
            print("\n📝 OCR Recognition Results Summary")
            print("================================")
            
            var totalConfidence: Double = 0
            var totalResults: Int = 0
            
            // 按语言分组打印结果
            for (language, languageResults) in results {
                print("\n🌐 Language: \(language.rawValue)")
                print("--------------------------------")
                
                // 按置信度排序并打印文本
                let sortedResults = languageResults.sorted { $0.confidence > $1.confidence }
                for (index, result) in sortedResults.enumerated() {
                    print("[\(index + 1)] (\(String(format: "%.2f", result.confidence * 100))%) \(result.text)")
                    totalConfidence += Double(result.confidence)
                    totalResults += 1
                }
            }
            
            // 打印格式化的文本结果
            print("\n📄 Formatted Text Result")
            print("--------------------------------")
            print(self.getFormattedText(from: results))
            
            print("\n📊 Statistics")
            print("--------------------------------")
            if let metrics = self.getMetrics() {
                print("⏱️ Processing Time: \(String(format: "%.2f", metrics.processingTime))s")
                print("📏 Image Size: \(metrics.imageSize)")
            }
            print("📈 Average Confidence: \(String(format: "%.2f", (totalResults > 0 ? totalConfidence / Double(totalResults) * 100 : 0)))%")
            print("📑 Total Results: \(totalResults)")
            print("================================\n")
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

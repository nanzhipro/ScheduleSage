//
//  WebContentExtractor.swift
//  ScheduleSage
//
//  Created by 南朋友 on 2024/03/26.
//

import Foundation
import SwiftSoup

// MARK: - Error Types
enum WebContentError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case parsingError(Error)
    case emptyContent
    case timeout
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的 URL"
        case .networkError(let error):
            return "网络错误: \(error.localizedDescription)"
        case .parsingError(let error):
            return "解析错误: \(error.localizedDescription)"
        case .emptyContent:
            return "未找到有效内容"
        case .timeout:
            return "请求超时"
        }
    }
}

// MARK: - Content Model
struct WebContent {
    let title: String
    let mainContent: String
    let metadata: WebMetadata
    
    struct WebMetadata {
        let url: URL
        let timestamp: Date
        let description: String?
        let keywords: [String]
    }
}

// MARK: - Extractor Protocol
protocol WebContentExtracting {
    func extract(from url: URL) async throws -> WebContent
    func extract(from urls: [URL]) async throws -> [WebContent]
}

// MARK: - Main Extractor
final class WebContentExtractor: WebContentExtracting {
    // MARK: - Properties
    private let session: URLSession
    private let timeout: TimeInterval
    private let retryCount: Int
    
    // MARK: - Initialization
    init(
        timeout: TimeInterval = 30,
        retryCount: Int = 2,
        configuration: URLSessionConfiguration = .default
    ) {
        self.timeout = timeout
        self.retryCount = retryCount
        
        // 配置 URLSession
        configuration.timeoutIntervalForRequest = timeout
        configuration.timeoutIntervalForResource = timeout
        self.session = URLSession(configuration: configuration)
    }
    
    // MARK: - Public Methods
    func extract(from url: URL) async throws -> WebContent {
        var lastError: Error?
        
        // 重试机制
        for attempt in 0...retryCount {
            do {
                if attempt > 0 {
                    try await Task.sleep(nanoseconds: UInt64(1_000_000_000 * attempt))
                }
                return try await performExtraction(from: url)
            } catch {
                lastError = error
                continue
            }
        }
        
        throw lastError ?? WebContentError.networkError(NSError(domain: "", code: -1))
    }
    
    func extract(from urls: [URL]) async throws -> [WebContent] {
        try await withThrowingTaskGroup(of: WebContent.self) { group in
            for url in urls {
                group.addTask {
                    try await self.extract(from: url)
                }
            }
            
            var results: [WebContent] = []
            for try await content in group {
                results.append(content)
            }
            return results
        }
    }
    
    // MARK: - Private Methods
    private func performExtraction(from url: URL) async throws -> WebContent {
        // 1. 加载网页内容
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw WebContentError.networkError(NSError(domain: "", code: -1))
        }
        
        // 2. 检测编码并转换为字符串
        let encoding = detectEncoding(from: httpResponse, data: data)
        guard let html = String(data: data, encoding: encoding) else {
            throw WebContentError.parsingError(NSError(domain: "", code: -1))
        }
        
        // 3. 解析 HTML
        let document = try SwiftSoup.parse(html)
        
        // 4. 提取内容
        let title = try document.title()
        let mainContent = try extractMainContent(from: document)
        let metadata = try extractMetadata(from: document, url: url)
        
        // 5. 验证内容
        guard !mainContent.isEmpty else {
            throw WebContentError.emptyContent
        }
        
        return WebContent(
            title: title,
            mainContent: mainContent,
            metadata: metadata
        )
    }
    
    private func detectEncoding(from response: HTTPURLResponse, data: Data) -> String.Encoding {
        // 从 HTTP 头中检测编码
        if let contentType = response.allHeaderFields["Content-Type"] as? String,
           let charset = contentType.split(separator: "=").last,
           let encoding = charset.lowercased().encoding {
            return encoding
        }
        
        // 尝试检测 HTML meta 标签中的编码
        if let html = String(data: data, encoding: .utf8),
           let metaCharset = try? extractMetaCharset(from: html) {
            return metaCharset
        }
        
        // 默认使用 UTF-8
        return .utf8
    }
    
    private func extractMainContent(from document: Document) throws -> String {
        // 移除无用元素
        try document.select("script, style, nav, header, footer, .ad").remove()
        
        // 提取主要内容区域
        let article = try document.select("article, .article, .content, .main").first()
        let mainContent = try article?.text() ?? document.body()?.text() ?? ""
        
        return mainContent.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func extractMetadata(from document: Document, url: URL) throws -> WebContent.WebMetadata {
        let description = try document.select("meta[name=description]").first()?.attr("content")
        let keywords = try document.select("meta[name=keywords]").first()?.attr("content")
            .split(separator: ",")
            .map(String.init)
            .map { $0.trimmingCharacters(in: .whitespaces) } ?? []
        
        return WebContent.WebMetadata(
            url: url,
            timestamp: Date(),
            description: description,
            keywords: keywords
        )
    }
    
    private func extractMetaCharset(from html: String) throws -> String.Encoding? {
        let document = try SwiftSoup.parse(html)
        if let charset = try document.select("meta[charset]").first()?.attr("charset") {
            return charset.lowercased().encoding
        }
        return nil
    }
}

// MARK: - Helper Extensions
private extension String {
    var encoding: String.Encoding? {
        switch self.lowercased() {
        case "utf-8": return .utf8
        case "utf8": return .utf8
        case "ascii": return .ascii
        case "iso-8859-1": return .isoLatin1
        case "unicode": return .unicode
        default: return nil
        }
    }
} 
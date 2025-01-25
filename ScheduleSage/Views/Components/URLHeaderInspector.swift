//
//  URLHeaderInspector.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024.03.19.
//

import Foundation

public enum URLHeaderInspectorError: LocalizedError {
  case invalidURL
  case networkError(Error)
  case invalidResponse
  case missingMIMEType
  case timeout
  case tooManyRedirects
  case requestFailed(Int)

  public var errorDescription: String? {
    switch self {
    case .invalidURL:
      return "无效的 URL"
    case .networkError(let error):
      return "网络错误: \(error.localizedDescription)"
    case .invalidResponse:
      return "无效的响应"
    case .missingMIMEType:
      return "未找到 MIME 类型"
    case .timeout:
      return "请求超时"
    case .tooManyRedirects:
      return "重定向次数过多"
    case .requestFailed(let statusCode):
      return "请求失败: HTTP \(statusCode)"
    }
  }
}

public protocol URLHeaderInspecting {
  func getHeaders(for url: URL, timeout: TimeInterval?) async throws -> [AnyHashable: Any]
  func getMIMEType(for url: URL, timeout: TimeInterval?) async throws -> String
  func isImageURL(_ url: URL, timeout: TimeInterval?) async throws -> Bool
  func isHTMLPage(_ url: URL, timeout: TimeInterval?) async throws -> Bool
}

public final class URLHeaderInspector: URLHeaderInspecting {
  public static let shared = URLHeaderInspector()

  private let queue = DispatchQueue(
    label: "com.quest.urlheaderinspector",
    attributes: .concurrent
  )
  private let cache = NSCache<NSURL, NSDictionary>()
  private let defaultTimeout: TimeInterval = 30
  private let maxRetries = 3

  private let session: URLSession
  private let imageTypes = Set([
    "image/jpeg",
    "image/png",
    "image/gif",
    "image/webp",
    "image/heic",
    "image/heif",
    "image/svg+xml",
  ])

  private let htmlTypes = Set([
    "text/html",
    "application/xhtml+xml",
  ])

  private init() {
    let configuration = URLSessionConfiguration.default
    configuration.timeoutIntervalForRequest = defaultTimeout
    configuration.requestCachePolicy = .returnCacheDataElseLoad
    configuration.urlCache = URLCache(
      memoryCapacity: 50 * 1024 * 1024,  // 50 MB
      diskCapacity: 100 * 1024 * 1024,  // 100 MB
      diskPath: "URLHeaderInspector"
    )

    self.session = URLSession(configuration: configuration)

    // 设置缓存限制
    cache.countLimit = 100
    cache.totalCostLimit = 50 * 1024 * 1024  // 50 MB
  }

  private func createRequest(for url: URL, timeout: TimeInterval?) -> URLRequest {
    var request = URLRequest(url: url)
    request.timeoutInterval = timeout ?? defaultTimeout
    request.cachePolicy = .returnCacheDataElseLoad
    return request
  }

  private func performRequest(_ request: URLRequest, retryCount: Int = 0) async throws -> (Data, HTTPURLResponse) {
    do {
      let (data, response) = try await session.data(for: request)

      guard let httpResponse = response as? HTTPURLResponse else {
        throw URLHeaderInspectorError.invalidResponse
      }

      // 检查状态码
      switch httpResponse.statusCode {
      case 200...299:
        return (data, httpResponse)
      case 300...399:
        throw URLHeaderInspectorError.tooManyRedirects
      default:
        throw URLHeaderInspectorError.requestFailed(httpResponse.statusCode)
      }
    } catch {
      if retryCount < maxRetries {
        // 指数退避重试
        try await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(retryCount)) * 1_000_000_000))
        return try await performRequest(request, retryCount: retryCount + 1)
      }
      throw URLHeaderInspectorError.networkError(error)
    }
  }

  public func getHeaders(for url: URL, timeout: TimeInterval? = nil) async throws -> [AnyHashable: Any] {
    // 检查缓存
    if let cachedHeaders = cache.object(forKey: url as NSURL) {
      return cachedHeaders as! [AnyHashable: Any]
    }

    let request = createRequest(for: url, timeout: timeout)
    let (_, response) = try await performRequest(request)

    // 存储到缓存
    let headers = response.allHeaderFields
    queue.async {
      self.cache.setObject(headers as NSDictionary, forKey: url as NSURL)
    }

    return headers
  }

  public func getMIMEType(for url: URL, timeout: TimeInterval? = nil) async throws -> String {
    let headers = try await getHeaders(for: url, timeout: timeout)

    guard let contentType = headers["Content-Type"] as? String else {
      throw URLHeaderInspectorError.missingMIMEType
    }

    return contentType.components(separatedBy: ";").first?.trimmingCharacters(in: .whitespaces) ?? contentType
  }

  public func isImageURL(_ url: URL, timeout: TimeInterval? = nil) async throws -> Bool {
    let mimeType = try await getMIMEType(for: url, timeout: timeout)
    return imageTypes.contains(mimeType.lowercased())
  }

  public func isHTMLPage(_ url: URL, timeout: TimeInterval? = nil) async throws -> Bool {
    let mimeType = try await getMIMEType(for: url, timeout: timeout)
    return htmlTypes.contains(mimeType.lowercased())
  }
}

// 便捷静态方法
public extension URL {
  func getHeaders(timeout: TimeInterval? = nil) async throws -> [AnyHashable: Any] {
    try await URLHeaderInspector.shared.getHeaders(for: self, timeout: timeout)
  }

  func getMIMEType(timeout: TimeInterval? = nil) async throws -> String {
    try await URLHeaderInspector.shared.getMIMEType(for: self, timeout: timeout)
  }

  func isImageURL(timeout: TimeInterval? = nil) async throws -> Bool {
    try await URLHeaderInspector.shared.isImageURL(self, timeout: timeout)
  }

  func isHTMLPage(timeout: TimeInterval? = nil) async throws -> Bool {
    try await URLHeaderInspector.shared.isHTMLPage(self, timeout: timeout)
  }
}

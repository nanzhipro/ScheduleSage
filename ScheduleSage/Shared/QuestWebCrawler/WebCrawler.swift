// Sources/SwiftWebCrawler/WebCrawler.swift

import Foundation
import SwiftSoup
import WebKit

public class WebCrawler: NSObject, WKNavigationDelegate {
  private let configuration: CrawlerConfiguration
  private let robotsParser = RobotsTxtParser()
  private let rateLimiter: RateLimiter
  public let session: URLSession
  private let logger: Logger?
  private let semaphore: AsyncSemaphore
  private let resultsActor = ResultsActor()
  private var webView: WKWebView?
  
  // 将isDisposed改为actor隔离
  @MainActor private var isDisposed = false

  /// Initialize WebCrawler with a configuration and an optional logger
  /// - Parameters:
  ///   - configuration: CrawlerConfiguration instance
  ///   - logger: Optional Logger instance for logging (default: nil)
  public init(configuration: CrawlerConfiguration = CrawlerConfiguration(), logger: Logger? = nil) {
    self.configuration = configuration
    self.rateLimiter = RateLimiter(minInterval: configuration.minRequestInterval)
    self.semaphore = AsyncSemaphore(value: configuration.maxConcurrentTasks)

    let sessionConfig = URLSessionConfiguration.default
    sessionConfig.httpAdditionalHeaders = ["User-Agent": configuration.userAgent]

    // Configure proxy if provided
    if let proxyConfig = configuration.proxy {
      switch proxyConfig.type {
      case .http:
        sessionConfig.connectionProxyDictionary = [
          kCFNetworkProxiesHTTPEnable as String: true,
          kCFNetworkProxiesHTTPProxy as String: proxyConfig.host,
          kCFNetworkProxiesHTTPPort as String: proxyConfig.port,
        ]
      case .https:
        sessionConfig.connectionProxyDictionary = [
          kCFNetworkProxiesHTTPSEnable as String: true,
          kCFNetworkProxiesHTTPSProxy as String: proxyConfig.host,
          kCFNetworkProxiesHTTPSPort as String: proxyConfig.port,
        ]
      case .socks:
        sessionConfig.connectionProxyDictionary = [
          kCFNetworkProxiesSOCKSEnable as String: true,
          kCFNetworkProxiesSOCKSProxy as String: proxyConfig.host,
          kCFNetworkProxiesSOCKSPort as String: proxyConfig.port,
        ]
      }

      // Handle proxy authentication if needed
      if let username = proxyConfig.username, let password = proxyConfig.password {
        let protectionSpace = URLProtectionSpace(
          host: proxyConfig.host,
          port: proxyConfig.port,
          protocol: proxyConfig.type == .http
            ? "http" : (proxyConfig.type == .https ? "https" : "socks"),
          realm: nil,
          authenticationMethod: NSURLAuthenticationMethodDefault
        )
        let credential = URLCredential(user: username, password: password, persistence: .forSession)
        URLCredentialStorage.shared.set(credential, for: protectionSpace)
      }
    }

    self.session = URLSession(configuration: sessionConfig)
    self.logger = logger
    super.init()
  }
  
  deinit {
    // 在deinit中不能直接调用@MainActor方法，使用非隔离版本的清理
    cleanupOnDeinit()
  }
  
  /// 非MainActor隔离的清理方法，专用于deinit
  private func cleanupOnDeinit() {
    // 取消会话中的任务
    session.invalidateAndCancel()
    
    // 发送一个任务到主线程执行UI相关的清理
    Task { @MainActor [weak self] in
      guard let self = self else { return }
      
      // 标记为已处置
      self.isDisposed = true
      
      // 取消任何挂起的continuation
      if let continuation = self.pendingContinuation {
        continuation.resume(throwing: WebCrawlerError.parsingFailed)
        self.pendingContinuation = nil
      }
      
      // 清理WebView
      self.webView?.stopLoading()
      self.webView?.navigationDelegate = nil
      self.webView = nil
      
      self.logger?.log("WebCrawler resources cleaned up from deinit")
    }
  }

  /// Crawl a single URL and return the extracted text
  /// - Parameter urlString: The URL string to crawl
  /// - Returns: Result containing extracted text or an error
  public func crawl(urlString: String) async -> Result<String, WebCrawlerError> {
    // 检查是否已处置
    guard await !isDisposed else {
      logger?.log("WebCrawler instance is disposed")
      return .failure(.parsingFailed)
    }
    
    guard let url = URL(string: urlString) else {
      logger?.log("Invalid URL: \(urlString)")
      return .failure(.invalidURL)
    }

    // Check URL scheme
    guard url.scheme == "http" || url.scheme == "https" else {
      logger?.log("Unsupported URL scheme for URL: \(urlString)")
      return .failure(.unsupportedURLScheme)
    }

    // Check robots.txt if enabled
    if configuration.obeyRobotsTxt {
      do {
        let rule = try await robotsParser.fetchAndParse(
          for: url, userAgent: configuration.userAgent)
        if !robotsParser.isAllowed(url: url, rule: rule) {
          logger?.log("Crawling disallowed by robots.txt for URL: \(urlString)")
          return .failure(.robotsTxtDisallowed)
        }

        // Apply crawl-delay if specified
        if let delay = rule.crawlDelay {
          logger?.log("Applying crawl-delay of \(delay) seconds for URL: \(urlString)")
          try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
      } catch let error as WebCrawlerError {
        logger?.log("Error fetching robots.txt for URL: \(urlString) - \(error.description)")
        return .failure(error)
      } catch {
        logger?.log("Unknown error fetching robots.txt for URL: \(urlString)")
        return .failure(.robotsTxtFetchFailed)
      }
    }

    // Apply rate limiting
    if let host = url.host {
      await rateLimiter.wait(for: host)
    }

    // Fetch HTML content
    do {
      let (data, response) = try await session.data(from: url)

      if let httpResponse = response as? HTTPURLResponse,
        !(200...299).contains(httpResponse.statusCode)
      {
        logger?.log(
          "Request failed for URL: \(urlString) with status code: \(httpResponse.statusCode)")
        return .failure(.requestFailed(statusCode: httpResponse.statusCode))
      }

      // Attempt to decode data with multiple encodings
      let encodings: [String.Encoding] = [.utf8, .isoLatin1, .windowsCP1252]
      var htmlContent: String? = nil
      for encoding in encodings {
        if let decoded = String(data: data, encoding: encoding) {
          htmlContent = decoded
          break
        }
      }

      guard let html = htmlContent else {
        logger?.log("Decoding failed for URL: \(urlString)")
        return .failure(.decodingFailed)
      }

      // Parse HTML and extract text
      let text = try extractText(from: html)
      logger?.log("Crawling succeeded for URL: \(urlString). Text length: \(text.count)")
      return .success(text)
    } catch let error as WebCrawlerError {
      logger?.log("Crawling failed for URL: \(urlString). Error: \(error.description)")
      return .failure(error)
    } catch {
      logger?.log("Crawling failed for URL: \(urlString). Unknown error.")
      return .failure(.parsingFailed)
    }
  }

  /// Crawl multiple URLs concurrently with a limit on the number of concurrent tasks
  /// - Parameter urls: Array of URL strings to crawl
  /// - Returns: Dictionary mapping URL strings to their crawl results
  public func crawlBatch(urls: [String]) async -> [String: Result<String, WebCrawlerError>] {
    // 检查是否已处置
    guard await !isDisposed else {
      logger?.log("WebCrawler instance is disposed")
      return urls.reduce(into: [:]) { $0[$1] = .failure(.parsingFailed) }
    }
    
    var results: [String: Result<String, WebCrawlerError>] = [:]

    await withTaskGroup(of: (String, Result<String, WebCrawlerError>).self) { group in
      for url in urls {
        group.addTask { [weak self] in
          guard let self = self, 
                // 使用await检查actor隔离属性
                await !self.isDisposed else {
            return (url, .failure(.parsingFailed))
          }

          await self.semaphore.wait()

          let result = await self.crawl(urlString: url)

          await self.semaphore.signal()

          return (url, result)
        }
      }

      for await (url, result) in group {
        await resultsActor.setResult(for: url, result: result)
      }
    }

    results = await resultsActor.getResults()
    return results
  }

  /// Extract text content from HTML string
  /// - Parameter html: HTML string to parse
  /// - Throws: WebCrawlerError.parsingFailed if parsing fails
  /// - Returns: Extracted plain text
  private func extractText(from html: String) throws -> String {
    do {
      let document: Document = try SwiftSoup.parse(html)
      
      // 1. 移除无用标签
      try document.select("script, style, noscript").remove()
      
      // 2. 提取关键内容区域
      let content = try document.select("#js_content").first()
      
      // 3. 处理特殊属性
      try content?.select("[data-src]").forEach { element in
        if let src = try? element.attr("data-src") {
          try element.attr("src", src)
        }
      }
      
      // 4. 格式化文本
      let text = try content?.text() ?? ""
      return text.trimmingCharacters(in: .whitespacesAndNewlines)
        .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    } catch {
      throw WebCrawlerError.parsingFailed
    }
  }

  func crawl(url: URL) async throws -> String {
    // 检查是否已处置
    guard await !isDisposed else {
      throw WebCrawlerError.parsingFailed
    }
    
    // 按需创建webView
    if webView == nil {
      let config = WKWebViewConfiguration()
      self.webView = WKWebView(frame: .zero, configuration: config)
    }
    
    guard let webView = self.webView else {
      throw WebCrawlerError.parsingFailed
    }
    
    return try await withCheckedThrowingContinuation { continuation in
      webView.navigationDelegate = self
      webView.load(URLRequest(url: url))
      
      // 存储continuation以便在页面加载完成后使用
      self.pendingContinuation = continuation
    }
  }
  
  // 添加一个属性来存储continuation
  private var pendingContinuation: CheckedContinuation<String, Error>?
  
  // 实现WKNavigationDelegate方法
  public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    webView.evaluateJavaScript("""
      document.querySelector('#js_content').innerText
    """) { [weak self] result, error in
      guard let self = self else { return }
      
      if let error = error {
        self.pendingContinuation?.resume(throwing: error)
      } else if let text = result as? String {
        self.pendingContinuation?.resume(returning: text)
      } else {
        self.pendingContinuation?.resume(throwing: WebCrawlerError.parsingFailed)
      }
      
      self.pendingContinuation = nil
    }
  }
  
  // 处理导航失败的情况
  public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
    pendingContinuation?.resume(throwing: error)
    pendingContinuation = nil
  }
  
  public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
    pendingContinuation?.resume(throwing: error)
    pendingContinuation = nil
  }

  private func createRequest(for urlString: String) throws -> URLRequest {
    guard let url = URL(string: urlString) else {
      throw WebCrawlerError.invalidURL
    }
    
    var request = URLRequest(url: url)
    request.allHTTPHeaderFields = [
        "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1",
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        "Accept-Language": "en-US,en;q=0.5",
        "Connection": "keep-alive",
        "Upgrade-Insecure-Requests": "1"
    ]
    return request
  }
  
  /// 清理资源，防止内存泄漏
  @MainActor
  public func cleanup() {
    guard !isDisposed else { return }
    
    isDisposed = true
    
    // 取消任何挂起的continuation
    if let continuation = pendingContinuation {
      continuation.resume(throwing: WebCrawlerError.parsingFailed)
      pendingContinuation = nil
    }
    
    // 清理WebView - 已经在主线程，无需再次分发
    webView?.stopLoading()
    webView?.navigationDelegate = nil
    webView = nil
    
    // 取消会话中的任务
    session.invalidateAndCancel()
    
    logger?.log("WebCrawler resources cleaned up")
  }
  
  /// 销毁实例并释放资源
  @MainActor
  public func dispose() {
    cleanup()
  }
}

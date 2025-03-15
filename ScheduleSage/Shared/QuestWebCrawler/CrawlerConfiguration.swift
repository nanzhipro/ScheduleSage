// Sources/SwiftWebCrawler/CrawlerConfiguration.swift

import Foundation

public enum ProxyType {
  case http
  case https
  case socks
}

public struct ProxyConfiguration {
  public var type: ProxyType
  public var host: String
  public var port: Int
  public var username: String?
  public var password: String?

  /// Initialize ProxyConfiguration
  /// - Parameters:
  ///   - type: ProxyType (default: .http)
  ///   - host: Proxy server host
  ///   - port: Proxy server port
  ///   - username: Optional username for proxy authentication
  ///   - password: Optional password for proxy authentication
  public init(
    type: ProxyType = .http, host: String, port: Int, username: String? = nil,
    password: String? = nil
  ) {
    self.type = type
    self.host = host
    self.port = port
    self.username = username
    self.password = password
  }
}

public struct CrawlerConfiguration {
  /// Whether to obey robots.txt rules
  public var obeyRobotsTxt: Bool

  /// User-Agent string to be used in HTTP requests
  public var userAgent: String

  /// Minimum interval between requests to the same host (in seconds)
  public var minRequestInterval: TimeInterval

  /// Optional proxy configuration
  public var proxy: ProxyConfiguration?

  /// Maximum number of concurrent crawling tasks
  public var maxConcurrentTasks: Int

  /// Initialize CrawlerConfiguration
  /// - Parameters:
  ///   - obeyRobotsTxt: Whether to obey robots.txt (default: false)
  ///   - userAgent: Custom User-Agent string (default: "SwiftWebCrawler/1.0")
  ///   - minRequestInterval: Minimum interval between requests (default: 2.0)
  ///   - proxy: Optional ProxyConfiguration (default: nil)
  ///   - maxConcurrentTasks: Maximum number of concurrent tasks (default: 5)
  public init(
    obeyRobotsTxt: Bool = false,
    userAgent: String = "SwiftWebCrawler/1.0",
    minRequestInterval: TimeInterval = 2.0,
    proxy: ProxyConfiguration? = nil,
    maxConcurrentTasks: Int = 5
  ) {
    self.obeyRobotsTxt = obeyRobotsTxt
    self.userAgent = userAgent
    self.minRequestInterval = minRequestInterval
    self.proxy = proxy
    self.maxConcurrentTasks = maxConcurrentTasks
  }
}

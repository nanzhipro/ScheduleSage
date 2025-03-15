// Sources/SwiftWebCrawler/RobotsTxtParser.swift

import Foundation

public struct RobotsTxtRule {
  let allowPaths: [String]
  let disallowPaths: [String]
  let crawlDelay: TimeInterval?
}

public class RobotsTxtParser {
  private var rules: RobotsTxtRule?

  public init() {}

  /// Fetch and parse robots.txt
  /// - Parameters:
  ///   - url: The URL of the website to fetch robots.txt
  ///   - userAgent: The User-Agent string to use
  /// - Returns: Parsed RobotsTxtRule
  public func fetchAndParse(for url: URL, userAgent: String) async throws -> RobotsTxtRule {
    // Construct robots.txt URL
    guard let scheme = url.scheme, let host = url.host else {
      throw WebCrawlerError.invalidURL
    }
    let robotsUrlString = "\(scheme)://\(host)/robots.txt"
    guard let robotsUrl = URL(string: robotsUrlString) else {
      throw WebCrawlerError.robotsTxtFetchFailed
    }

    // Create a new URLSession to avoid affecting the main session's configuration
    let sessionConfig = URLSessionConfiguration.default
    sessionConfig.httpAdditionalHeaders = ["User-Agent": userAgent]
    let session = URLSession(configuration: sessionConfig)

    do {
      let (data, response) = try await session.data(from: robotsUrl)

      guard let httpResponse = response as? HTTPURLResponse,
        (200...299).contains(httpResponse.statusCode)
      else {
        throw WebCrawlerError.robotsTxtFetchFailed
      }

      guard let content = String(data: data, encoding: .utf8) else {
        throw WebCrawlerError.decodingFailed
      }

      return try parse(content: content, userAgent: userAgent)
    } catch {
      throw WebCrawlerError.robotsTxtFetchFailed
    }
  }

  /// Parse robots.txt content
  /// - Parameters:
  ///   - content: The content of robots.txt
  ///   - userAgent: The User-Agent string to check rules for
  /// - Returns: Parsed RobotsTxtRule
  private func parse(content: String, userAgent: String) throws -> RobotsTxtRule {
    let lines = content.components(separatedBy: .newlines)
    var allowPaths: [String] = []
    var disallowPaths: [String] = []
    var crawlDelay: TimeInterval? = nil
    var applicable = false

    for line in lines {
      // Remove comments and trim whitespace
      let cleanedLine =
        line.components(separatedBy: "#").first?.trimmingCharacters(in: .whitespacesAndNewlines)
        .lowercased() ?? ""
      if cleanedLine.hasPrefix("user-agent:") {
        let agent = cleanedLine.replacingOccurrences(of: "user-agent:", with: "")
          .trimmingCharacters(in: .whitespaces)
        applicable = (agent == "*" || agent == userAgent.lowercased())
      } else if applicable {
        if cleanedLine.hasPrefix("disallow:") {
          let path = cleanedLine.replacingOccurrences(of: "disallow:", with: "").trimmingCharacters(
            in: .whitespaces)
          if !path.isEmpty {
            disallowPaths.append(path)
          }
        } else if cleanedLine.hasPrefix("allow:") {
          let path = cleanedLine.replacingOccurrences(of: "allow:", with: "").trimmingCharacters(
            in: .whitespaces)
          if !path.isEmpty {
            allowPaths.append(path)
          }
        } else if cleanedLine.hasPrefix("crawl-delay:") {
          let delayStr = cleanedLine.replacingOccurrences(of: "crawl-delay:", with: "")
            .trimmingCharacters(in: .whitespaces)
          if let delay = TimeInterval(delayStr) {
            crawlDelay = delay
          }
        }
      }
    }

    // 修复参数顺序：allowPaths 在 disallowPaths 之前
    return RobotsTxtRule(
      allowPaths: allowPaths, disallowPaths: disallowPaths, crawlDelay: crawlDelay)
  }

  /// Check if URL is allowed to be crawled
  /// - Parameters:
  ///   - url: The URL to check
  ///   - rule: The RobotsTxtRule to apply
  /// - Returns: `true` if allowed, `false` otherwise
  public func isAllowed(url: URL, rule: RobotsTxtRule) -> Bool {
    guard let path = url.path.removingPercentEncoding else { return false }

    // Allow rules have higher priority
    for allow in rule.allowPaths {
      if path.hasPrefix(allow) {
        return true
      }
    }

    for disallow in rule.disallowPaths {
      if disallow == "/" {
        return false
      }
      if path.hasPrefix(disallow) {
        return false
      }
    }

    return true
  }
}

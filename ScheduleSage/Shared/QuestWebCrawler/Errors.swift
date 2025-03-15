// Sources/SwiftWebCrawler/Errors.swift

import Foundation

public enum WebCrawlerError: Error, CustomStringConvertible, Equatable {
  case invalidURL
  case requestFailed(statusCode: Int)
  case decodingFailed
  case parsingFailed
  case robotsTxtDisallowed
  case robotsTxtFetchFailed
  case robotsTxtParsingFailed
  case unsupportedURLScheme

  public var description: String {
    switch self {
    case .invalidURL:
      return "Invalid URL."
    case .requestFailed(let statusCode):
      return "Request failed with status code: \(statusCode)."
    case .decodingFailed:
      return "Failed to decode data."
    case .parsingFailed:
      return "Failed to parse HTML."
    case .robotsTxtDisallowed:
      return "Crawling disallowed by robots.txt."
    case .robotsTxtFetchFailed:
      return "Failed to fetch robots.txt."
    case .robotsTxtParsingFailed:
      return "Failed to parse robots.txt."
    case .unsupportedURLScheme:
      return "Unsupported URL scheme."
    }
  }

  // Implement Equatable for testing purposes
  public static func == (lhs: WebCrawlerError, rhs: WebCrawlerError) -> Bool {
    switch (lhs, rhs) {
    case (.invalidURL, .invalidURL),
      (.decodingFailed, .decodingFailed),
      (.parsingFailed, .parsingFailed),
      (.robotsTxtDisallowed, .robotsTxtDisallowed),
      (.robotsTxtFetchFailed, .robotsTxtFetchFailed),
      (.robotsTxtParsingFailed, .robotsTxtParsingFailed),
      (.unsupportedURLScheme, .unsupportedURLScheme):
      return true
    case (.requestFailed(let lhsCode), .requestFailed(let rhsCode)):
      return lhsCode == rhsCode
    default:
      return false
    }
  }
}

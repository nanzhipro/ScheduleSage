// Sources/SwiftWebCrawler/ResultsActor.swift

import Foundation

actor ResultsActor {
  private var results: [String: Result<String, WebCrawlerError>] = [:]

  func setResult(for url: String, result: Result<String, WebCrawlerError>) {
    results[url] = result
  }

  func getResults() -> [String: Result<String, WebCrawlerError>] {
    return results
  }
}

// Sources/SwiftWebCrawler/Logger.swift

import Foundation

public protocol Logger {
  func log(_ message: String)
}

public class ConsoleLogger: Logger {
  public init() {}

  public func log(_ message: String) {
    print("[SwiftWebCrawler] \(message)")
  }
}

// Sources/SwiftWebCrawler/RateLimiter.swift

import Foundation

public class RateLimiter {
  private var lastRequestTime: [String: Date] = [:]
  private let queue = DispatchQueue(label: "RateLimiterQueue")
  private let minInterval: TimeInterval

  /// Initialize RateLimiter with a minimum interval between requests (in seconds)
  /// - Parameter minInterval: Minimum time interval between requests to the same host
  public init(minInterval: TimeInterval = 2.0) {
    self.minInterval = minInterval
  }

  /// Wait until the next request can be sent to the specified host
  /// - Parameter host: The host to apply rate limiting
  public func wait(for host: String) async {
    await withCheckedContinuation { continuation in
      queue.async {
        let now = Date()
        if let lastTime = self.lastRequestTime[host] {
          let elapsed = now.timeIntervalSince(lastTime)
          if elapsed < self.minInterval {
            let delay = self.minInterval - elapsed
            DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
              self.lastRequestTime[host] = Date()
              continuation.resume()
            }
            return
          }
        }
        self.lastRequestTime[host] = Date()
        continuation.resume()
      }
    }
  }
}

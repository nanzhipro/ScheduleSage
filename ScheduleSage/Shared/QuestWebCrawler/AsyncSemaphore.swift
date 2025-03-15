// Sources/SwiftWebCrawler/AsyncSemaphore.swift

import Foundation

public actor AsyncSemaphore {
  private var permits: Int
  private var waiters: [CheckedContinuation<Void, Never>] = []

  public init(value: Int) {
    self.permits = value
  }

  public func wait() async {
    if permits > 0 {
      permits -= 1
    } else {
      await withCheckedContinuation { continuation in
        waiters.append(continuation)
      }
    }
  }

  public func signal() async {  // 将 signal() 标记为 async
    if !waiters.isEmpty {
      let continuation = waiters.removeFirst()
      continuation.resume()
    } else {
      permits += 1
    }
  }
}

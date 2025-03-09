import Alamofire
import Foundation

/// 分级网络日志系统
/// - 重要: 生产环境应关闭DEBUG级别日志
public final class NetworkLogger: EventMonitor {
  public enum LogLevel: Int, Sendable {
    case verbose  // 记录所有细节
    case debug  // 开发调试信息
    case info  // 常规运行信息
    case warning  // 需要关注的异常
    case error  // 严重错误
  }

  public static let shared = NetworkLogger()
  private let logLevel: LogLevel
  private let sensitiveHeaders: Set<String> = ["Cookie"]

  init(logLevel: LogLevel = .debug) {
    self.logLevel = logLevel
  }

  // MARK: - Request Lifecycle
  public func request(_ request: Request, didCreateURLRequest urlRequest: URLRequest) {
    guard logLevel.rawValue <= LogLevel.debug.rawValue else { return }

    let headers = redactSensitiveHeaders(urlRequest.headers)
    log(
      level: .debug,
      message: """
      🚀 RequestCreated [\(request.id)]
      │ URL:      \(urlRequest.url?.absoluteString ?? "nil")
      │ Method:   \(urlRequest.httpMethod ?? "N/A")
      │ Headers:  \(headers)
      """
    )
  }

  func request(_ request: Request, didParseResponse response: DataResponse<Data?, AFError>) {
    let statusCode = response.response?.statusCode ?? 0
    let level: LogLevel = statusCode >= 400 ? .error : .info

    log(
      level: level,
      message: """
      📥 ResponseReceived [\(request.id)]
      │ URL:        \(response.request?.url?.absoluteString ?? "nil")
      │ Status:     \(statusCode)
      │ Duration:   \(String(format: "%.2f", request.metrics?.taskInterval.duration ?? 0))s
      │ DataSize:   \(response.data?.count ?? 0) bytes
      """
    )
  }

  // MARK: - Authentication Logs
  func logUnauthorizedAttempt(request: Request) {
    log(
      level: .warning,
      message: """
      🔐 UnauthorizedRequest [\(request.id)]
      │ URL:            \(request.request?.url?.absoluteString ?? "nil")
      │ RetryAttempts:  \(request.retryCount)
      │ LastStatusCode: \(request.response?.statusCode ?? 0)
      """
    )
  }

  func logTokenRefresh(result: Result<String, Error>) {
    switch result {
    case .success(let token):
      log(
        level: .info,
        message: """
        ✅ TokenRefreshSuccess
        │ NewToken:   \(token.prefix(8))... (Length: \(token.count))
        │ ExpiresAt:  \(Date().addingTimeInterval(300).ISO8601Format())
        """
      )
    case .failure(let error):
      log(
        level: .error,
        message: """
        ❌ TokenRefreshFailure
        │ ErrorType:  \(type(of: error))
        │ Reason:     \(error.localizedDescription)
        """
      )
    }
  }

  // MARK: - Utility Methods
  public func log(level: LogLevel, message: String) {
    guard level.rawValue >= logLevel.rawValue else { return }

    let emoji: String
    switch level {
    case .verbose: emoji = "📝"
    case .debug: emoji = "🔍"
    case .info: emoji = "ℹ️"
    case .warning: emoji = "⚠️"
    case .error: emoji = "❌"
    }

    print("\(emoji) [\(level)] \(message)")
  }

  private func redactSensitiveHeaders(_ headers: HTTPHeaders) -> [String: String] {
    var result = [String: String]()
    for header in headers {
      result[header.name] = sensitiveHeaders.contains(header.name) ? "*****" : header.value
    }
    return result
  }

  func logTokenEvent(_ event: TokenEvent) {
    switch event {
    case .refreshSuccess:
      log(level: .info, message: "✅ Token refresh successful")
    case .refreshFailure(let error):
      log(level: .error, message: "❌ Token refresh failed: \(error.localizedDescription)")
    case .tokenExpired:
      log(level: .warning, message: "⚠️ Token expired")
    case .tokenInvalid:
      log(level: .warning, message: "⚠️ Token invalid")
    case .tokenAdded:
      log(level: .debug, message: "🔑 Token added to request")
    }
  }
}

extension DateFormatter {
  static let iso8601: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
    return formatter
  }()
}

extension Date {
  func ISO8601Format() -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter.string(from: self)
  }
}

public enum TokenEvent {
  case refreshSuccess
  case refreshFailure(Error)
  case tokenExpired
  case tokenInvalid
  case tokenAdded
}

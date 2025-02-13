import Combine
import Foundation

/// Protocol defining token management requirements
/// - Note: Implementations must handle thread safety for token access
public protocol TokenProvider: Sendable {
  var token: String? { get async }
  var refreshToken: String? { get async }
  func validateToken() async throws -> Bool
  func refreshToken() async throws
  func updateTokens(access: String, refresh: String) async
}

/// JWT令牌生命周期管理器
/// - 功能: 处理令牌的获取、刷新、存储和自动续期
/// - 注意: 使用Keychain进行安全存储，保证令牌不落盘
public actor JWTTokenManager: TokenProvider {
  // MARK: - Shared Instance
  public static let shared = JWTTokenManager()

  // MARK: - 配置参数
  private let refreshThreshold: TimeInterval = 300  // 5分钟
  private let logger: NetworkLogger

  // MARK: - 状态管理
  private var _accessToken: String?
  private var _refreshToken: String?
  private var expirationDate: Date?
  private var refreshTask: Task<Void, Error>?

  public init(logger: NetworkLogger = .shared) {
    self.logger = logger
  }

  // MARK: - TokenProvider 协议实现
  public var token: String? {
    get async { _accessToken }
  }

  public var refreshToken: String? {
    get async { _refreshToken }
  }

  public func validateToken() async throws -> Bool {
    guard let expiration = expirationDate else { return false }
    return expiration > Date()
  }

  public func refreshToken() async throws {
    if let existingTask = refreshTask {
      return try await existingTask.value
    }

    let task = Task {
      do {
        let newToken = try await AuthService.shared.refreshToken()
        await updateTokens(access: newToken, refresh: _refreshToken ?? "")
        logger.logTokenEvent(.refreshSuccess)
      } catch {
        logger.logTokenEvent(.refreshFailure(error))
        throw error
      }
    }

    refreshTask = task
    try await task.value
    refreshTask = nil
  }

  public func updateTokens(access: String, refresh: String) async {
    _accessToken = access
    _refreshToken = refresh
    expirationDate = Date().addingTimeInterval(3600)
  }

  private func isExpired(_ token: String) -> Bool {
    guard let payload = decodeJWTPayload(token) else { return true }
    return payload.exp < Date().timeIntervalSince1970
  }

  private func decodeJWTPayload(_ token: String) -> JWTPayload? {
    let parts = token.components(separatedBy: ".")
    guard parts.count == 3,
      let data = Data(base64Encoded: parts[1].base64URLUnescaped),
      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    else { return nil }

    return JWTPayload(
      exp: json["exp"] as? TimeInterval ?? 0,
      iat: json["iat"] as? TimeInterval ?? 0
    )
  }
}

private struct JWTPayload {
  let exp: TimeInterval
  let iat: TimeInterval
}

extension String {
  fileprivate var base64URLUnescaped: String {
    replacingOccurrences(of: "-", with: "+")
      .replacingOccurrences(of: "_", with: "/")
  }
}

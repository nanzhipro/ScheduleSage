import Foundation

/// 认证凭证
/// - Note: 用于初始化认证和刷新令牌
public struct AuthCredentials {
  /// 客户端标识
  public let clientId: String

  /// 客户端密钥
  public let clientSecret: String

  /// 创建认证凭证
  /// - Parameters:
  ///   - clientId: 客户端标识，默认为 "default_client"
  ///   - clientSecret: 客户端密钥，默认为 "default_secret"
  public init(
    clientId: String = "QuestService",
    clientSecret: String = "QuestSecret"
  ) {
    self.clientId = clientId
    self.clientSecret = clientSecret
  }

  /// 默认凭证实例
  public static let `default` = AuthCredentials()

  /// 转换为认证请求参数
  /// - Returns: 包含认证参数的字典
  public func asParameters() -> [String: String] {
    [
      "client_id": clientId,
      "client_secret": clientSecret,
      "grant_type": "client_credentials",
    ]
  }
}

// MARK: - Equatable
extension AuthCredentials: Equatable {}

// MARK: - Codable
extension AuthCredentials: Codable {}

// MARK: - CustomStringConvertible
extension AuthCredentials: CustomStringConvertible {
  public var description: String {
    "AuthCredentials(clientId: \(clientId))"
  }
}

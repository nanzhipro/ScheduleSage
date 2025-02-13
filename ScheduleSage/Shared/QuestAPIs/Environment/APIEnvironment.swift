//
//  APIAPIEnvironment.swift
//  QuestAPIs
//
//  Created by CursorAI on 2024-03-20.
//

import Alamofire
/// Represents the application's APIEnvironment configuration
/// - Note: Ensure APIEnvironment is set before making any network requests
/// - Important: Base URLs must be HTTPS and properly configured for each APIEnvironment
import Foundation

/// 环境配置结构体
/// - 功能: 定义网络请求的基础环境参数
/// - 注意: 使用前必须正确配置环境参数
/// - 重要: baseURL必须使用HTTPS协议，并确保配置正确
public struct APIEnvironment: Equatable {
  /// 基础URL地址
  public let baseURL: URL

  /// 默认请求头
  public let defaultHeaders: HTTPHeaders

  /// 环境标识符
  public let identifier: String

  /// 初始化环境配置
  /// - 参数:
  ///   - baseURL: API基础地址
  ///   - defaultHeaders: 默认请求头
  ///   - identifier: 环境标识符
  public init(
    baseURL: URL,
    defaultHeaders: HTTPHeaders = [:],
    identifier: String
  ) {
    // 验证baseURL是否合法
    assert(
      baseURL.absoluteString.hasPrefix("http"),
      "BaseURL must start with http:// or https://"
    )

    self.baseURL = baseURL
    self.defaultHeaders = defaultHeaders
    self.identifier = identifier
  }

  /// 创建新的环境配置
  /// - 参数:
  ///   - modifying: 需要修改的环境配置
  ///   - transform: 修改闭包
  /// - 返回: 新的环境配置实例
  public func with(_ transform: (inout APIEnvironment) -> Void) -> APIEnvironment {
    var copy = self
    transform(&copy)
    return copy
  }

  /// 添加默认请求头
  /// - 参数:
  ///   - headers: 新的请求头
  /// - 返回: 包含新请求头的环境配置
  public func addingHeaders(_ headers: HTTPHeaders) -> APIEnvironment {
    var newHeaders = self.defaultHeaders
    headers.forEach { newHeaders.add($0) }
    return APIEnvironment(
      baseURL: baseURL,
      defaultHeaders: newHeaders,
      identifier: identifier
    )
  }
}

// MARK: - CustomStringConvertible
extension APIEnvironment: CustomStringConvertible {
  public var description: String {
    "APIEnvironment(baseURL: \(baseURL.absoluteString), identifier: \(identifier))"
  }
}

// MARK: - 示例代码（仅供参考）
/*
// 在业务层定义具体环境
extension APIEnvironment {
    static let development = APIEnvironment(
        baseURL: URL(string: "https://dev-api.example.com")!,
        defaultHeaders: [
            "Accept": "application/json",
            "Accept-Language": Locale.preferredLanguages.joined(separator: ", ")
        ],
        identifier: "development"
    )

    static let production = APIEnvironment(
        baseURL: URL(string: "https://api.example.com")!,
        defaultHeaders: [
            "Accept": "application/json",
            "Accept-Language": Locale.preferredLanguages.joined(separator: ", ")
        ],
        identifier: "production"
    )
}
*/

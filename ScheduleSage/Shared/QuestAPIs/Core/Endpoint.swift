//
//  Endpoint.swift
//  QuestAPIs
//
//  Created by CursorAI on 2024-03-20.
//

import Alamofire
import Foundation

/// API端点协议
/// - 功能: 定义统一的接口配置规范
/// - 注意: 具体实现应该在客户端应用层创建
public protocol Endpoint {
  /// 接口路径（相对基础URL）
  var path: String { get }

  /// HTTP方法
  var method: HTTPMethod { get }

  /// 请求参数
  var parameters: Parameters? { get }

  /// 参数编码方式
  var encoding: ParameterEncoding { get }

  /// 请求头（可选覆盖全局配置）
  var headers: HTTPHeaders? { get }

  /// 超时时间（可选覆盖全局配置）
  var timeout: TimeInterval? { get }

  /// 缓存策略（可选）
  var cachePolicy: URLRequest.CachePolicy? { get }
}

// MARK: - 默认实现
extension Endpoint {
  public var parameters: Parameters? { nil }
  public var headers: HTTPHeaders? { nil }
  public var timeout: TimeInterval? { nil }
  public var cachePolicy: URLRequest.CachePolicy? { nil }
  public var encoding: ParameterEncoding {
    method == .get ? URLEncoding.default : JSONEncoding.default
  }
}

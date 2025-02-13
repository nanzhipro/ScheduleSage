//
//  AuthService.swift
//  QuestAPIs
//
//  Created by CursorAI on 2024-03-20.
//

import Alamofire
import Foundation

/// 认证服务核心处理
/// - 功能: 处理JWT令牌的获取与刷新
public final class AuthService {
  private static var _shared: AuthService?

  public static var shared: AuthService {
    get {
      guard let instance = _shared else {
        preconditionFailure(
          "AuthService.configure(with:) must be called before accessing shared instance")
      }
      return instance
    }
    set {
      _shared = newValue
    }
  }

  public static func configure(with environment: APIEnvironment) {
    shared = AuthService(environment: environment)
  }

  private let client: APIClient
  private let tokenManager: TokenProvider

  public init(
    environment: APIEnvironment,
    tokenManager: TokenProvider = JWTTokenManager.shared
  ) {
    self.tokenManager = tokenManager
    self.client = APIClient(
      environment: environment,
      tokenProvider: tokenManager
    )
  }

  public func authenticate(credentials: AuthCredentials = .default) async throws {
    let result: Result<AuthResponse, APIError> = await client.request(
      AuthEndpoint.login,
      parameters: credentials.asParameters()
    )

    switch result {
    case .success(let response):
      await tokenManager.updateTokens(
        access: response.accessToken,
        refresh: response.refreshToken
      )
    case .failure(let error):
      throw AuthError(apiError: error)
    }
  }

  public func refreshToken() async throws -> String {
    let currentRefreshToken = await tokenManager.refreshToken ?? ""
    let result: Result<AuthResponse, APIError> = await client.request(
      AuthEndpoint.refreshToken,
      parameters: ["refresh_token": currentRefreshToken]
    )

    switch result {
    case .success(let response):
      await tokenManager.updateTokens(
        access: response.accessToken,
        refresh: response.refreshToken
      )
      return response.accessToken
    case .failure(let error):
      throw AuthError(apiError: error)
    }
  }
}

private enum AuthEndpoint: Endpoint {
  case login, refreshToken

  var path: String {
    switch self {
    case .login: return "/api/login"
    case .refreshToken: return "/api/token"
    }
  }

  var method: HTTPMethod { .post }
  var encoding: ParameterEncoding { JSONEncoding.default }
}

private struct AuthResponse: Decodable {
  let accessToken: String
  let refreshToken: String
  let expiresIn: Int
  let tokenType: String

  enum CodingKeys: String, CodingKey {
    case accessToken = "access_token"
    case refreshToken = "refresh_token"
    case expiresIn = "expires_in"
    case tokenType = "token_type"
  }
}

public enum AuthError: LocalizedError {
  case invalidGrant
  case serverError
  case networkError

  init(apiError: APIError) {
    switch apiError {
    case .server(401): self = .invalidGrant
    case .server: self = .serverError
    default: self = .networkError
    }
  }
}

// 修改Parameters类型定义
public typealias Parameters = Alamofire.Parameters

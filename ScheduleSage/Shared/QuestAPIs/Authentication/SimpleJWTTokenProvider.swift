//
//  SimpleJWTTokenProvider.swift
//  QuestAPIs
//
//  Created by CursorAI on 2024-03-20.
//

import Alamofire
import Foundation

/// 简单JWT令牌提供者
/// - 功能: 提供基础的JWT令牌获取和管理功能
public actor SimpleJWTTokenProvider: TokenProvider {
  private var jwtToken: String?
  private let environment: APIEnvironment
  private let credentials: AuthCredentials
  
  public init(environment: APIEnvironment, credentials: AuthCredentials = .default) {
    self.environment = environment
    self.credentials = credentials
  }
  
  public var token: String? {
    get async { jwtToken }
  }
  
  public var refreshToken: String? {
    get async { nil }  // 简化版不支持刷新令牌
  }
  
  public func validateToken() async throws -> Bool {
    jwtToken != nil
  }
  
  public func refreshToken() async throws {
    // 简化版不支持刷新令牌
    throw APIError.authRequired
  }
  
  public func updateTokens(access: String, refresh: String) async {
    self.jwtToken = access
  }
  
  public func fetchToken() async throws -> String {
    let client = APIClient(environment: environment)
    
    let result: Result<JWTTokenResponse, APIError> = await client.request(
      JWTAuthTokenEndpoint.getToken,
      parameters: credentials.asParameters()
    )
    
    switch result {
    case .success(let response):
      self.jwtToken = response.jwtToken
      return response.jwtToken
    case .failure(let error):
      throw error
    }
  }
}

private enum JWTAuthTokenEndpoint: Endpoint {
  case getToken
  
  var path: String {
    switch self {
    case .getToken: return "/api/get_jwt_token"
    }
  }
  
  var method: HTTPMethod { .get }
}

private struct JWTTokenResponse: Decodable {
  let jwtToken: String
  
  enum CodingKeys: String, CodingKey {
    case jwtToken = "jwt_token"
  }
} 
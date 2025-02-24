//
//  SimpleJWTTokenProvider.swift
//  QuestAPIs
//
//  Created by CursorAI on 2024-03-20.
//

import Alamofire
import Foundation
import SwiftJWT

/// 提供 JWT 令牌管理的类型
/// - 职责:
///   - 管理 JWT 令牌的生命周期
///   - 处理令牌的获取、验证和刷新
///   - 确保令牌在多个并发请求中的一致性
/// - 注意:
///   - 使用 actor 确保线程安全
///   - 自动处理令牌过期和刷新
///   - 支持令牌提前刷新以避免过期
public actor SimpleJWTTokenProvider: TokenProvider {
    // MARK: - Properties
    
    /// 当前的 JWT 令牌
    private var jwtToken: String?
    
    /// 令牌的过期时间
    private var tokenExpirationDate: Date?
    
    /// API 环境配置
    private let environment: APIEnvironment
    
    /// 认证凭据
    private let credentials: AuthCredentials
    
    /// 令牌刷新的提前时间（秒）
    /// - Note: 在令牌过期前 60 秒开始刷新，避免过期导致的服务中断
    private let refreshThreshold: TimeInterval = 60
    
    // MARK: - Initialization
    
    /// 创建令牌提供者实例
    /// - Parameters:
    ///   - environment: API 环境配置
    ///   - credentials: 认证凭据，默认使用 .default
    public init(environment: APIEnvironment, credentials: AuthCredentials = .default) {
        self.environment = environment
        self.credentials = credentials
    }
    
    public var token: String? {
        get async { jwtToken }
    }
    
    public var refreshToken: String? {
        get async { nil }
    }
    
    private func parseTokenExpiration(_ token: String) {
        do {
            // 使用 SwiftJWT 解析 token
            let parts = token.components(separatedBy: ".")
            guard parts.count == 3,
                  let payload = parts[1].base64URLDecoded(),
                  let json = try JSONSerialization.jsonObject(with: payload, options: []) as? [String: Any],
                  let exp = json["exp"] as? TimeInterval
            else {
                tokenExpirationDate = nil
                return
            }
            
            tokenExpirationDate = Date(timeIntervalSince1970: exp)
        } catch {
            tokenExpirationDate = nil
        }
    }
    
    private func isTokenExpired() -> Bool {
        guard let expirationDate = tokenExpirationDate else {
            return true
        }
        return Date() >= expirationDate
    }
    
    private func isTokenNearExpiration() -> Bool {
        guard let expirationDate = tokenExpirationDate else {
            return true
        }
        let refreshDate = expirationDate.addingTimeInterval(-refreshThreshold)
        return Date() >= refreshDate
    }
    
    public func validateToken() async throws -> Bool {
        guard let token = jwtToken else {
            return false
        }
        
        if isTokenExpired() {
            return false
        }
        
        if isTokenNearExpiration() {
            let newToken = try await fetchToken()
            return newToken == token
        }
        
        return true
    }
    
    public func refreshToken() async throws {
        let newToken = try await fetchToken()
        self.jwtToken = newToken
        parseTokenExpiration(newToken)
    }
    
    public func updateTokens(access: String, refresh: String) async {
        self.jwtToken = access
        parseTokenExpiration(access)
    }
    
    public func fetchToken() async throws -> String {
        let client = APIClient(
            environment: environment,
            tokenProvider: self
        )
        
        let result: Result<JWTTokenResponse, APIError> = await client.request(
            JWTAuthTokenEndpoint.getToken,
            parameters: credentials.asParameters()
        )
        
        switch result {
        case .success(let response):
            self.jwtToken = response.token
            parseTokenExpiration(response.token)
            return response.token
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
  
  var method: HTTPMethod { .post }
}

private struct JWTTokenResponse: Decodable {
  let token: String
}

// 添加 Base64URL 解码扩展
private extension String {
    func base64URLDecoded() -> Data? {
        var base64 = self
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        if base64.count % 4 != 0 {
            base64.append(String(repeating: "=", count: 4 - base64.count % 4))
        }
        
        return Data(base64Encoded: base64)
    }
} 

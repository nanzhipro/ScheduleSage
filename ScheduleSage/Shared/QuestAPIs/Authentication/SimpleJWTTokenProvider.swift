//
//  SimpleJWTTokenProvider.swift
//  QuestAPIs
//
//  Created by CursorAI on 2024-03-20.
//

import Alamofire
import Foundation
import SwiftJWT

/// 简单JWT令牌提供者
/// Simple JWT Token Provider
/// - 功能: 
///   - 提供基础的JWT令牌获取和管理功能
///   - 支持令牌过期检测和自动刷新
///   - 处理并发请求时的令牌更新
public actor SimpleJWTTokenProvider: TokenProvider {
    private var jwtToken: String?
    private var tokenExpirationDate: Date?
    private let environment: APIEnvironment
    private let credentials: AuthCredentials
    
    // 令牌提前刷新的时间阈值（默认60秒）
    private let refreshThreshold: TimeInterval = 60
    
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
            try await refreshToken()
        }
        
        return true
    }
    
    public func refreshToken() async throws {
        try await fetchToken()
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

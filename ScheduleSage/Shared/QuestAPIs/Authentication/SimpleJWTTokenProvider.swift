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
    
    /// 日志服务
    private let logger = LoggerService.logger(category: "JWTTokenProvider")
    
    // MARK: - Initialization
    
    /// 创建令牌提供者实例
    /// - Parameters:
    ///   - environment: API 环境配置
    ///   - credentials: 认证凭据，默认使用 .default
    public init(environment: APIEnvironment, credentials: AuthCredentials = .default) {
        self.environment = environment
        self.credentials = credentials
        
        logger.info("[JWTTokenProvider] JWT Token Provider initialized with environment: \(environment.baseURL)")
    }
    
    public var token: String? {
        get async { 
            if let jwtToken {
                logger.info("[JWTTokenProvider] Retrieved current JWT token: \(jwtToken.prefix(8))... (length: \(jwtToken.count))")
            } else {
                logger.info("[JWTTokenProvider] No JWT token available")
            }
            return jwtToken 
        }
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
                Task {
                    logger.warning("[JWTTokenProvider] Failed to parse token expiration - invalid token format")
                }
                return
            }
            
            tokenExpirationDate = Date(timeIntervalSince1970: exp)
            
            Task {
                if let expirationDate = tokenExpirationDate {
                    logger.info("[JWTTokenProvider] Token expiration parsed successfully - expires at: \(expirationDate.ISO8601Format())")
                }
            }
        } catch {
            tokenExpirationDate = nil
            Task {
                logger.error("[JWTTokenProvider] Error parsing token expiration: \(error.localizedDescription)")
            }
        }
    }
    
    private func isTokenExpired() -> Bool {
        guard let expirationDate = tokenExpirationDate else {
            Task {
                logger.info("[JWTTokenProvider] Token considered expired - no expiration date available")
            }
            return true
        }
        
        let isExpired = Date() >= expirationDate
        
        if isExpired {
            Task {
                logger.info("[JWTTokenProvider] Token is expired - current time: \(Date().ISO8601Format()), expiration: \(expirationDate.ISO8601Format())")
            }
        }
        
        return isExpired
    }
    
    private func isTokenNearExpiration() -> Bool {
        guard let expirationDate = tokenExpirationDate else {
            Task {
                logger.info("[JWTTokenProvider] Token considered near expiration - no expiration date available")
            }
            return true
        }
        
        let refreshDate = expirationDate.addingTimeInterval(-refreshThreshold)
        let isNearExpiration = Date() >= refreshDate
        
        if isNearExpiration {
            Task {
                logger.info("[JWTTokenProvider] Token is near expiration - current time: \(Date().ISO8601Format()), refresh threshold: \(refreshThreshold)s, expiration: \(expirationDate.ISO8601Format())")
            }
        }
        
        return isNearExpiration
    }
    
    public func validateToken() async throws -> Bool {
        logger.info("[JWTTokenProvider] Validating JWT token")
        
        guard let token = jwtToken else {
            logger.info("[JWTTokenProvider] Token validation failed - no token available")
            return false
        }
        
        if isTokenExpired() {
            logger.info("[JWTTokenProvider] Token validation failed - token is expired")
            return false
        }
        
        if isTokenNearExpiration() {
            logger.info("[JWTTokenProvider] Token near expiration - attempting refresh")
            let newToken = try await fetchToken()
            let isValid = newToken == token
            logger.info("[JWTTokenProvider] Token refresh result: \(isValid ? "unchanged" : "refreshed")")
            return isValid
        }
        
        logger.info("[JWTTokenProvider] Token validation successful - token is valid")
        return true
    }
    
    public func refreshToken() async throws {
        logger.info("[JWTTokenProvider] Refreshing JWT token")
        
        let newToken = try await fetchToken()
        self.jwtToken = newToken
        parseTokenExpiration(newToken)
        
        logger.info("[JWTTokenProvider] JWT token refreshed successfully")
    }
    
    public func updateTokens(access: String, refresh: String) async {
        logger.info("[JWTTokenProvider] Updating JWT token - new token length: \(access.count)")
        
        self.jwtToken = access
        parseTokenExpiration(access)
    }
    
    public func fetchToken() async throws -> String {
        logger.info("[JWTTokenProvider] Fetching new JWT token from server")
        
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
            logger.info("[JWTTokenProvider] JWT token fetched successfully - token length: \(response.token.count)")
            self.jwtToken = response.token
            parseTokenExpiration(response.token)
            return response.token
        case .failure(let error):
            logger.error("[JWTTokenProvider] Failed to fetch JWT token: \(error.localizedDescription)")
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


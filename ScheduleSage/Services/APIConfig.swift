//
//  APIConfig.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-02-22.
//

import Foundation
import OSLog
import Alamofire

// MARK: - APIConfig
final class APIConfig {
    // MARK: - Singleton
    static let shared = APIConfig()
    
    // MARK: - Properties
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "ScheduleSage", category: "APIConfig")
    private let tokenProvider: SimpleJWTTokenProvider
    private let environment: APIEnvironment
    
    // MARK: - API Environment
    static let developmentEnvironment = APIEnvironment(
        baseURL: URL(string: "http://localhost:8080")!,
        defaultHeaders: [
            "Accept": "application/json",
            "Content-Type": "application/json",
            "Accept-Language": Locale.preferredLanguages.first ?? "en"
        ],
        identifier: "development"
    )
    
    static let ngrokEnvironment = APIEnvironment(
        baseURL: URL(string: "https://ec63-115-195-71-161.ngrok-free.app")!,
        defaultHeaders: [
            "Accept": "application/json",
            "Content-Type": "application/json",
            "Accept-Language": Locale.preferredLanguages.first ?? "en"
        ],
        identifier: "ngrok"
    )
    
    static let productionEnvironment = APIEnvironment(
        baseURL: URL(string: "https://www.schedulesage.cn")!,
        defaultHeaders: [
            "Accept": "application/json",
            "Content-Type": "application/json",
            "Accept-Language": Locale.preferredLanguages.first ?? "en"
        ],
        identifier: "production"
    )
    
    // MARK: - Current Environment
    var currentAPIEnvironment: APIEnvironment {
        environment
    }
    
    // MARK: - Computed Properties
    var baseURL: String {
        currentAPIEnvironment.baseURL.absoluteString
    }
    
    var promptsEndpoint: String {
        "\(baseURL)/api/v1/prompts"
    }
    
    var llmEndpoint: String {
        "\(baseURL)/api/v1/llm/chat"
    }
    
    // MARK: - Initialization
    private init() {
        logger.info("APIConfig initialized")
        
        // 首先确定环境
        #if DEBUG
        // 使用环境变量或配置来决定是使用本地开发环境还是 ngrok 环境
        if ProcessInfo.processInfo.environment["USE_NGROK"] == "true" {
            self.environment = Self.ngrokEnvironment
            logger.debug("Using ngrok environment: \(Self.ngrokEnvironment)")
        } else {
            self.environment = Self.developmentEnvironment
            logger.debug("Using development environment: \(Self.developmentEnvironment)")
        }
        #else
        self.environment = Self.productionEnvironment
        logger.debug("Using production environment: \(Self.productionEnvironment)")
        #endif
        
        // 初始化 tokenProvider
        self.tokenProvider = SimpleJWTTokenProvider(
            environment: environment,
            credentials: .default
        )
        
        // 配置 APIClient
        APIClient.configure(
            with: environment,
            tokenProvider: tokenProvider
        )
        
        // 初始化 token
        Task { [self] in
            do {
                _ = try await tokenProvider.fetchToken()
                logger.info("Successfully initialized JWT token")
            } catch {
                logger.error("Failed to initialize JWT token: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Public Interface
    
    /// 获取当前的 token provider
    /// - Returns: SimpleJWTTokenProvider 实例
    public func getTokenProvider() -> SimpleJWTTokenProvider {
        tokenProvider
    }
} 

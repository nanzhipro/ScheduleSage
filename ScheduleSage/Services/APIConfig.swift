//
//  APIConfig.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-02-22.
//

import Foundation
import Alamofire

// MARK: - APIConfig
/// API 配置管理器
/// 负责管理 API 环境配置和认证状态
actor APIConfig {
    // MARK: - Singleton
    static let shared = APIConfig()
    
    // MARK: - Properties
    private let logger = LoggerService.makeCompatible(category: "APIConfig")
    private let tokenProvider: SimpleJWTTokenProvider
    
    // 将 environment 改为 nonisolated，因为它在初始化后不会改变
    private nonisolated let environment: APIEnvironment
    private var isTokenInitialized = false
    private var tokenInitializationTask: Task<Void, Error>?
    
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
    nonisolated var currentAPIEnvironment: APIEnvironment {
        environment // 现在可以安全访问 nonisolated 的 environment
    }
    
    // MARK: - Computed Properties
    nonisolated var baseURL: String {
        currentAPIEnvironment.baseURL.absoluteString
    }
    
    nonisolated var promptsEndpoint: String {
        "\(baseURL)/api/v1/prompts"
    }
    
    nonisolated var llmEndpoint: String {
        "\(baseURL)/api/v1/llm/chat"
    }
    
    // MARK: - Initialization
    private init() {
        logger.info("APIConfig initialized")
        
        // 首先确定环境
        #if DEBUG
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
    }
    
    // MARK: - Token Management
    
    /// 确保 JWT token 已经初始化
    /// - Throws: 如果 token 初始化失败则抛出错误
    public func ensureTokenInitialized() async throws {
        // 如果已经初始化完成，直接返回
        if isTokenInitialized {
            return
        }
        
        // 如果已经有任务在运行，等待其完成
        if let existingTask = tokenInitializationTask {
            try await existingTask.value
            return
        }
        
        // 创建新的初始化任务
        let task = Task {
            logger.info("Initializing JWT token...")
            do {
                _ = try await tokenProvider.fetchToken()
                isTokenInitialized = true
                logger.info("Successfully initialized JWT token")
            } catch {
                logger.error("Failed to initialize JWT token: \(error.localizedDescription)")
                throw error
            }
        }
        
        tokenInitializationTask = task
        
        // 等待任务完成并清理
        do {
            try await task.value
            tokenInitializationTask = nil
        } catch {
            tokenInitializationTask = nil
            throw error
        }
    }
    
    // MARK: - Public Interface
    
    /// 获取当前的 token provider
    /// - Returns: SimpleJWTTokenProvider 实例
    nonisolated public func getTokenProvider() -> SimpleJWTTokenProvider {
        tokenProvider
    }
} 

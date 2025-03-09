//
//  ConfigService.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-19.
//

import Foundation
import OSLog
import Alamofire

// MARK: - ConfigService
/// 应用配置服务
/// 负责从服务器获取应用配置信息
actor ConfigService {
    // MARK: - Properties
    private let logger: Logger
    private let apiConfig: APIConfig
    
    // MARK: - Initialization
    init(
        logger: Logger = .init(subsystem: Bundle.main.bundleIdentifier ?? "ScheduleSage", category: "ConfigService"),
        apiConfig: APIConfig = .shared
    ) {
        self.logger = logger
        self.apiConfig = apiConfig
    }
    
    // MARK: - Public Interface
    /// 从服务器获取应用配置
    /// - Returns: 应用配置信息
    /// - Throws: APIError
    func fetchConfig() async throws -> AppConfig {
        logger.info("Fetching app configuration...")
        
        // 确保 token 已初始化
        try await apiConfig.ensureTokenInitialized()
        
        let endpoint = ConfigEndpoint.getConfig
        let result: Result<AppConfig, APIError> = await APIClient.shared.request(endpoint)
        
        switch result {
        case .success(let config):
            logger.info("Successfully fetched app configuration")
            return config
        case .failure(let error):
            logger.error("Failed to fetch app configuration: \(error.localizedDescription)")
            throw error
        }
    }
}

// MARK: - Models
/// 应用配置模型
struct AppConfig: Codable {
    let revenuecatApiKey: String
}

// MARK: - Endpoint
/// 配置相关API端点
private enum ConfigEndpoint: Endpoint {
    /// 获取应用配置
    case getConfig
    
    var path: String {
        switch self {
        case .getConfig:
            return "/api/v1/config"
        }
    }
    
    var method: HTTPMethod { .get }
    
    var encoding: ParameterEncoding {
        URLEncoding.default
    }
}

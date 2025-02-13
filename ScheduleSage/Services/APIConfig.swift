//
//  APIConfig.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-02-22.
//

import Foundation
import OSLog

// MARK: - SSEnvironment
enum SSEnvironment {
    case development
    case staging
    case production
    
    var baseURL: String {
        switch self {
        case .development: return "http://localhost:8080"
        case .staging: return "https://www.schedulesage.cn"
        case .production: return "https://www.schedulesage.cn"
        }
    }
}

// MARK: - APIConfig
final class APIConfig {
    // MARK: - Singleton
    static let shared = APIConfig()
    
    // MARK: - Properties
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "ScheduleSage", category: "APIConfig")
    private let environment: SSEnvironment
    
    // MARK: - Computed Properties
    var baseURL: String {
        environment.baseURL
    }
    
    var promptsEndpoint: String {
        "\(baseURL)/api/v1/prompts"
    }
    
    var llmEndpoint: String {
        "\(baseURL)/api/v1/llm/chat"
    }
    
    // MARK: - Initialization
    private init() {
        #if DEBUG
        self.environment = .development
        logger.debug("API initialized with development environment")
        #else
        self.environment = .production
        logger.debug("API initialized with production environment")
        #endif
    }
} 

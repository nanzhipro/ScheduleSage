//
//  APIConfig.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-02-22.
//

import Foundation
import OSLog

// MARK: - APIEnvironment
enum APIEnvironment {
    case development
    case staging
    case production
    
    var baseURL: String {
        switch self {
        case .development: return "http://localhost:8080"
        case .staging: return "https://staging-api.schedulesage.app"
        case .production: return "https://api.schedulesage.app"
        }
    }
}

// MARK: - APIConfig
final class APIConfig {
    // MARK: - Singleton
    static let shared = APIConfig()
    
    // MARK: - Properties
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "ScheduleSage", category: "APIConfig")
    private let environment: APIEnvironment
    
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
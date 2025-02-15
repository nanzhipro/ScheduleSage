//
//  PromptService.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-02-22.
//

import Foundation
import OSLog
import Alamofire

// MARK: - Error Types
/// 提示词服务相关错误
public enum PromptError: LocalizedError {
    /// 网络请求失败
    case network(Error)
    /// 服务器响应无效
    case invalidResponse(Int)
    /// 数据解码失败
    case decoding(Error)
    /// 本地存储失败
    case storage(Error)
    
    public var errorDescription: String? {
        switch self {
        case .network(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse(let code):
            return "Invalid response: status code \(code)"
        case .decoding(let error):
            return "Decoding error: \(error.localizedDescription)"
        case .storage(let error):
            return "Storage error: \(error.localizedDescription)"
        }
    }
}

// MARK: - PromptService
/// 提示词服务
/// 负责管理提示词的获取、存储和自动更新
actor PromptService {
    // MARK: - Properties
    private let logger: Logger
    private let apiConfig: APIConfig
    private let storage: UserDefaults
    private let promptKey = "stored_prompt"
    private var refreshTask: Task<Void, Never>?
    
    /// 提示词刷新间隔（秒）
    private let refreshInterval: TimeInterval = 3600
    
    // MARK: - Initialization
    /// 创建提示词服务实例
    /// - Parameters:
    ///   - logger: 日志记录器
    ///   - apiConfig: API配置
    ///   - storage: 用户默认设置存储
    init(
        logger: Logger = .init(subsystem: Bundle.main.bundleIdentifier ?? "ScheduleSage", category: "PromptService"),
        apiConfig: APIConfig = .shared,
        storage: UserDefaults = .standard
    ) {
        self.logger = logger
        self.apiConfig = apiConfig
        self.storage = storage
        
        startPeriodicRefresh()
    }
    
    deinit {
        stopPeriodicRefresh()
    }
    
    // MARK: - Public Interface
    
    /// 从服务器获取最新提示词
    /// - Returns: 存储的提示词
    /// - Throws: PromptError
    /// - Complexity: O(1)
    func fetchLatestPrompt() async throws -> StoredPrompt {
        logger.info("Fetching latest prompt...")
        
        let currentVersion = getCurrentVersion()
        let url = URL(string: "\(apiConfig.promptsEndpoint)?version=\(currentVersion)")!
        
        do {
            let prompt = try await fetchPrompt(from: url)
            try await savePrompt(prompt)
            logger.info("Successfully updated prompt to version \(prompt.version)")
            return prompt
        } catch {
            logger.error("Failed to fetch prompt: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// 获取本地存储的提示词
    /// - Returns: 存储的提示词，如果不存在则返回nil
    /// - Complexity: O(1)
    func getStoredPrompt() -> StoredPrompt? {
        logger.debug("Retrieving stored prompt...")
        
        guard let data = storage.data(forKey: promptKey) else {
            logger.notice("No stored prompt found")
            return nil
        }
        
        do {
            let prompt = try JSONDecoder().decode(StoredPrompt.self, from: data)
            logger.debug("Retrieved prompt version \(prompt.version)")
            return prompt
        } catch {
            logger.error("Failed to decode stored prompt: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// 启动定期刷新任务
    /// - Note: 如果已存在刷新任务，此方法不会重复启动
    func startPeriodicRefresh() {
        guard refreshTask == nil else { return }
        
        refreshTask = Task {
            while !Task.isCancelled {
                do {
                    _ = try await fetchLatestPrompt()
                    logger.info("Scheduled prompt refresh completed")
                } catch {
                    logger.error("Scheduled prompt refresh failed: \(error.localizedDescription)")
                }
                
                try? await Task.sleep(nanoseconds: UInt64(refreshInterval * 1_000_000_000))
            }
        }
    }
    
    /// 停止定期刷新任务
    func stopPeriodicRefresh() {
        refreshTask?.cancel()
        refreshTask = nil
    }
    
    // MARK: - Private Helpers
    
    /// 获取当前提示词版本
    /// - Returns: 当前版本号，如果没有存储的提示词则返回0
    private func getCurrentVersion() -> Int {
        getStoredPrompt()?.version ?? 0
    }
    
    /// 从指定URL获取提示词
    /// - Parameter url: 提示词API地址
    /// - Returns: 提示词响应
    /// - Throws: PromptError
    private func fetchPrompt(from url: URL) async throws -> StoredPrompt {
        let endpoint = PromptEndpoint.getLatest(version: getCurrentVersion())
        
        let parameters: Parameters = [
            "version": getCurrentVersion()
        ]
        
        let result: Result<PromptResponse, APIError> = await APIClient.shared.request(
            endpoint,
            parameters: parameters
        )
        
        switch result {
        case .success(let promptResponse):
            return StoredPrompt(from: promptResponse)
        case .failure(let error):
            logger.error("Failed to fetch prompt: \(error.localizedDescription)")
            throw PromptError.network(error)
        }
    }
    
    /// 保存提示词到本地存储
    /// - Parameter prompt: 要保存的提示词
    /// - Throws: PromptError.storage
    private func savePrompt(_ prompt: StoredPrompt) async throws {
        do {
            let data = try JSONEncoder().encode(prompt)
            storage.set(data, forKey: promptKey)
            logger.debug("Saved prompt to storage")
        } catch {
            throw PromptError.storage(error)
        }
    }
}

// MARK: - Endpoint
/// 提示词相关API端点
private enum PromptEndpoint: Endpoint {
    /// 获取最新提示词
    case getLatest(version: Int)
    
    var path: String {
        switch self {
        case .getLatest:
            return "/api/v1/prompts"
        }
    }
    
    var method: HTTPMethod { .get }
    
    var encoding: ParameterEncoding {
        URLEncoding.queryString
    }
} 

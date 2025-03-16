//
//  LLMService.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-20.
//

import Foundation
import Alamofire

/// 提供大语言模型服务的类型
/// 负责处理与 LLM API 的通信和响应处理
public final class LLMService {
    // MARK: - Properties
    
    /// 共享的 LLM 服务实例
    public static let shared = LLMService()
    
    private let apiConfig: APIConfig
    private let logger = LoggerService.makeCompatible(category: "LLMService")
    
    // MARK: - Initialization
    
    private init(apiConfig: APIConfig = .shared) {
        self.apiConfig = apiConfig
    }
    
    // MARK: - Public Methods
    
    /// 发送聊天请求到 LLM 服务
    /// - Parameters:
    ///   - content: 用户输入的聊天内容
    ///   - temperature: 模型温度参数，控制输出的随机性。默认为 0.7
    ///   - model: 使用的模型标识符。默认为空字符串，使用服务端默认模型
    /// - Returns: LLM 的响应内容
    /// - Throws: APIError 类型的错误
    /// - Complexity: O(1)，但网络延迟可能显著影响响应时间
    public func chat(
        with content: String,
        temperature: Double = 0.3,
        model: String = ""
    ) async throws -> LLMResponse {
        let message = LLMMessage(role: .user, content: content)
        let config = LLMConfig(
            model: model,
            temperature: temperature
        )
        let request = LLMRequest(
            messages: [message],
            config: config
        )
        
        let parameters = try request.asDictionary()
        logger.info("LLM Chat Request: \(parameters)")
        
        return try await withAPIClient { client in
            try await client.performRequest(
                endpoint: LLMEndpoint.chat,
                parameters: parameters
            )
        }
    }
    
    // MARK: - Private Methods
    
    /// 在指定的 API 客户端上执行请求
    /// - Parameter operation: 要执行的异步操作
    /// - Returns: 操作的结果
    /// - Throws: APIError 类型的错误
    private func withAPIClient<T>(
        perform operation: (APIClient) async throws -> T
    ) async throws -> T {
        let result = try await operation(APIClient.shared)
        return result
    }
}

// MARK: - LLM Endpoint
private enum LLMEndpoint: Endpoint {
    /// 聊天接口端点
    case chat
    
    var path: String {
        switch self {
        case .chat:
            return "/api/v1/llm/chat"
        }
    }
    
    var method: HTTPMethod { .post }
    
    var encoding: ParameterEncoding {
        JSONEncoding.default
    }
}

// MARK: - API Client Extension
private extension APIClient {
    /// 执行 API 请求并处理响应
    /// - Parameters:
    ///   - endpoint: 请求的端点
    ///   - parameters: 请求参数
    /// - Returns: 解码后的响应对象
    /// - Throws: APIError 类型的错误
    func performRequest<T: Decodable>(
        endpoint: Endpoint,
        parameters: Parameters
    ) async throws -> T {
        let result: Result<T, APIError> = await request(
            endpoint,
            parameters: parameters
        )
        
        switch result {
        case .success(let response):
            return response
        case .failure(let error):
            throw error
        }
    }
}

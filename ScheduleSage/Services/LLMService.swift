//
//  LLMService.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-20.
//

import Foundation
import Alamofire

public class LLMService {
  private let apiConfig = APIConfig.shared
  
  public static let shared = LLMService()
  private init() {}
  
  public func chat(content: String) async throws -> LLMResponse {
    let message = LLMMessage(role: .user, content: content)
    let config = LLMConfig(model: "hunyuan-lite", temperature: 1.0)
    let request = LLMRequest(messages: [message], config: config)
    
    return try await AF.request(
      apiConfig.llmEndpoint,
      method: .post,
      parameters: request,
      encoder: JSONParameterEncoder(encoder: {
        let encoder = JSONEncoder()
        return encoder
      }())
    )
    .validate()
    .serializingDecodable(LLMResponse.self)
    .value
  }
  
  public func chatWithCustomConfig(request: LLMRequest) async throws -> LLMResponse {
    return try await AF.request(
      apiConfig.llmEndpoint,
      method: .post,
      parameters: request,
      encoder: JSONParameterEncoder(encoder: {
        let encoder = JSONEncoder()
        return encoder
      }())
    )
    .validate()
    .serializingDecodable(LLMResponse.self)
    .value
  }
} 
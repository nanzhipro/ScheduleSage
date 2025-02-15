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
    let config = LLMConfig(model: "", temperature: 0.7)
    let request = LLMRequest(messages: [message], config: config)
    
    let parameters = try request.asDictionary()
    
    let result: Result<LLMResponse, APIError> = await APIClient.shared.request(
      LLMEndpoint.chat,
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

// MARK: - Endpoint
private enum LLMEndpoint: Endpoint {
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

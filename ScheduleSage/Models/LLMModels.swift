//
//  LLMModels.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-20.
//

import Foundation

/// LLM 消息角色
public enum LLMRole: String, Sendable {
  case system = "system"
  case user = "user"
  case assistant = "assistant"
}

extension LLMRole: Codable {
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let rawValue = try container.decode(String.self)

    switch rawValue.lowercased() {
    case "system":
      self = .system
    case "user":
      self = .user
    case "assistant":
      self = .assistant
    default:
      throw DecodingError.dataCorruptedError(
        in: container,
        debugDescription: "Cannot initialize LLMRole from invalid String value: \(rawValue)"
      )
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}

/// LLM 消息结构
public struct LLMMessage: Codable, Sendable {
  public let role: LLMRole
  public let content: String

  public init(role: LLMRole, content: String) {
    self.role = role
    self.content = content
  }

  enum CodingKeys: String, CodingKey {
    case role = "Role"
    case content = "Content"
  }
}

/// LLM 请求配置
public struct LLMConfig: Codable, Sendable {
  public let model: String
  public let temperature: Double
  public var stream: Bool

  public init(
    model: String,
    temperature: Double = 0.7,
    stream: Bool = false
  ) {
    self.model = model
    self.temperature = temperature
    self.stream = stream
  }

  enum CodingKeys: String, CodingKey {
    case model = "Model"
    case temperature = "Temperature"
    case stream = "Stream"
  }
}

/// LLM 请求选项
public struct LLMRequest: Codable, Sendable {
  public let messages: [LLMMessage]
  public var config: LLMConfig

  public init(messages: [LLMMessage], config: LLMConfig) {
    self.messages = messages
    self.config = config
  }

  enum CodingKeys: String, CodingKey {
    case messages = "Messages"
    case model = "Model"
    case temperature = "Temperature"
    case stream = "Stream"
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    messages = try container.decode([LLMMessage].self, forKey: .messages)
    let model = try container.decode(String.self, forKey: .model)
    let temperature = try container.decodeIfPresent(Double.self, forKey: .temperature) ?? 0.7
    let stream = try container.decodeIfPresent(Bool.self, forKey: .stream) ?? false
    config = LLMConfig(model: model, temperature: temperature, stream: stream)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(messages, forKey: .messages)
    try container.encode(config.model, forKey: .model)
    try container.encode(config.temperature, forKey: .temperature)
    try container.encode(config.stream, forKey: .stream)
  }

  func asDictionary() throws -> [String: Any] {
    let encoder = JSONEncoder()
    let data = try encoder.encode(self)
    guard let dictionary = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
      throw APIError.invalidData(reason: "Failed to convert encoded data to dictionary")
    }
    return dictionary
  }
}

/// LLM 响应结构
public struct LLMResponse: Codable, Sendable {
  public let content: String // JSON Model
  public let requestId: String

  public init(content: String, requestId: String) {
    self.content = content
    self.requestId = requestId
  }

  enum CodingKeys: String, CodingKey {
    case content = "Content"
    case requestId = "RequestId"
  }
} 

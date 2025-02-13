//
//  PromptModels.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-02-22.
//

import Foundation

// MARK: - API Response
struct PromptResponse: Decodable {
    let content: String
    let version: Int
    
    private enum CodingKeys: String, CodingKey {
        case content = "content"
        case version = "version"
    }
}

// MARK: - Stored Model
struct StoredPrompt: Codable {
    let content: String
    let version: Int
    
    init(from response: PromptResponse) {
        self.content = response.content
        self.version = response.version
    }
}

// MARK: - API Request
struct PromptRequest: Encodable {
    let version: Int
    
    private enum CodingKeys: String, CodingKey {
        case version = "version"
    }
} 
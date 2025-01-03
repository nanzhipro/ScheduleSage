//
//  PromptModels.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-02-22.
//

import Foundation

struct PromptResponse: Codable {
    let version: Int
    let content: String
}

struct StoredPrompt: Codable {
    let version: Int
    let content: String
    let lastUpdated: Date
    
    init(from response: PromptResponse) {
        self.version = response.version
        self.content = response.content
        self.lastUpdated = Date()
    }
} 
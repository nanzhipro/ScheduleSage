//
//  PromptService.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-02-22.
//

import Foundation

enum PromptError: Error {
    case networkError(Error)
    case invalidResponse
    case decodingError
    case storageError
}

actor PromptService {
    private let baseURL = "http://localhost:8080/api"
    private let userDefaults = UserDefaults.standard
    private let promptKey = "stored_prompt"
    
    func fetchLatestPrompt() async throws -> StoredPrompt {
        let currentVersion = getCurrentVersion()
        let url = URL(string: "\(baseURL)/prompts?version=\(currentVersion)")!
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw PromptError.invalidResponse
        }
        
        let promptResponse = try JSONDecoder().decode(PromptResponse.self, from: data)
        let storedPrompt = StoredPrompt(from: promptResponse)
        
        try savePrompt(storedPrompt)
        return storedPrompt
    }
    
    func getStoredPrompt() -> StoredPrompt? {
        guard let data = userDefaults.data(forKey: promptKey) else { return nil }
        return try? JSONDecoder().decode(StoredPrompt.self, from: data)
    }
    
    private func getCurrentVersion() -> Int {
        getStoredPrompt()?.version ?? 0
    }
    
    private func savePrompt(_ prompt: StoredPrompt) throws {
        let data = try JSONEncoder().encode(prompt)
        userDefaults.set(data, forKey: promptKey)
    }
} 
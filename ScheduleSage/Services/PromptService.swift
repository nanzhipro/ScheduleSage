//
//  PromptService.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-02-22.
//

import Foundation
import OSLog

// MARK: - Error Types
enum PromptError: LocalizedError {
    case networkError(Error)
    case invalidResponse
    case decodingError
    case storageError
    
    var errorDescription: String? {
        switch self {
        case .networkError(let error): return "Network Error: \(error.localizedDescription)"
        case .invalidResponse: return "Invalid Server Response"
        case .decodingError: return "Data Decoding Error"
        case .storageError: return "Local Storage Error"
        }
    }
}

// MARK: - PromptService
actor PromptService {
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "ScheduleSage", category: "PromptService")
    private let apiConfig = APIConfig.shared
    private let userDefaults = UserDefaults.standard
    private let promptKey = "stored_prompt"
    
    // MARK: - Public Methods
    func fetchLatestPrompt() async throws -> StoredPrompt {
        logger.info("Initiating fetch for latest prompt...")
        
        let currentVersion = getCurrentVersion()
        let url = URL(string: "\(apiConfig.promptsEndpoint)?version=\(currentVersion)")!
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                logger.error("Invalid server response: status code \(String(describing: (response as? HTTPURLResponse)?.statusCode))")
                throw PromptError.invalidResponse
            }
            
            let promptResponse = try JSONDecoder().decode(PromptResponse.self, from: data)
            let storedPrompt = StoredPrompt(from: promptResponse)
            
            try await savePrompt(storedPrompt)
            logger.info("Successfully fetched and saved new prompt version: \(storedPrompt.version)")
            
            return storedPrompt
        } catch let error as DecodingError {
            logger.error("Failed to decode response: \(error.localizedDescription)")
            throw PromptError.decodingError
        } catch {
            logger.error("Network request failed: \(error.localizedDescription)")
            throw PromptError.networkError(error)
        }
    }
    
    func getStoredPrompt() -> StoredPrompt? {
        logger.debug("Attempting to retrieve stored prompt...")
        guard let data = userDefaults.data(forKey: promptKey) else {
            logger.notice("No stored prompt found in local storage")
            return nil
        }
        
        do {
            let prompt = try JSONDecoder().decode(StoredPrompt.self, from: data)
            logger.debug("Successfully retrieved stored prompt: version \(prompt.version)")
            return prompt
        } catch {
            logger.error("Failed to read stored prompt: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Private Methods
    private func getCurrentVersion() -> Int {
        getStoredPrompt()?.version ?? 0
    }
    
    private func savePrompt(_ prompt: StoredPrompt) async throws {
        do {
            let data = try JSONEncoder().encode(prompt)
            userDefaults.set(data, forKey: promptKey)
            logger.debug("Prompt successfully persisted to local storage")
        } catch {
            logger.error("Failed to save prompt: \(error.localizedDescription)")
            throw PromptError.storageError
        }
    }
} 

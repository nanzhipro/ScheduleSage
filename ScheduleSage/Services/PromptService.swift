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
enum PromptError: LocalizedError {
    case network(Error)
    case invalidResponse(Int)
    case decoding(Error)
    case storage(Error)
    
    var errorDescription: String? {
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
actor PromptService {
    // MARK: - Properties
    private let logger: Logger
    private let apiConfig: APIConfig
    private let storage: UserDefaults
    private let promptKey = "stored_prompt"
    
    // MARK: - Initialization
    init(
        logger: Logger = .init(subsystem: Bundle.main.bundleIdentifier ?? "ScheduleSage", category: "PromptService"),
        apiConfig: APIConfig = .shared,
        storage: UserDefaults = .standard
    ) {
        self.logger = logger
        self.apiConfig = apiConfig
        self.storage = storage
    }
    
    // MARK: - Public Methods
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
    
    // MARK: - Private Methods
    private func getCurrentVersion() -> Int {
        getStoredPrompt()?.version ?? 0
    }
    
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
private enum PromptEndpoint: Endpoint {
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

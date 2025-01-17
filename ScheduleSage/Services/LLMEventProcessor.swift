//
//  LLMEventProcessor.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-20.
//

import Foundation
import OSLog

public protocol LLMEventProcessor {
    func processContent(_ content: String) async throws -> [CalendarEvent]
}

public enum LLMEventProcessorError: LocalizedError {
    case invalidResponse
    case processingFailed(Error)
    case parsingFailed
    
    public var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return NSLocalizedString("llm_invalid_response", comment: "")
        case .processingFailed(let error):
            return error.localizedDescription
        case .parsingFailed:
            return NSLocalizedString("llm_parsing_failed", comment: "")
        }
    }
}

public class DefaultLLMEventProcessor: LLMEventProcessor {
    private let logger: Logger
    private let llmService: LLMService
    private let promptViewModel: PromptViewModel
    private let calendarManager: CalendarManager
    
    init(
        llmService: LLMService = .shared,
        promptViewModel: PromptViewModel,
        calendarManager: CalendarManager = CalendarManager(),
        logger: Logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "ScheduleSage", category: "LLMEventProcessor")
    ) {
        self.llmService = llmService
        self.promptViewModel = promptViewModel
        self.calendarManager = calendarManager
        self.logger = logger
    }
    
    public func processContent(_ content: String) async throws -> [CalendarEvent] {
        logger.info("Processing content with LLM")
        
        let calendarNames = await getCalendarNames()
        let prompt = try await buildPrompt(content: content, calendarNames: calendarNames)
        let response = try await llmService.chat(content: prompt)
        
        guard let event = CalendarEvent.from(llmResponse: response.content, logger: logger) else {
            throw LLMEventProcessorError.parsingFailed
        }
        
        return [event]
    }
    
    private func getCalendarNames() async -> [String] {
        guard (try? await calendarManager.requestAccess()) == true else {
            logger.warning("Calendar access denied")
            return []
        }
        return calendarManager.getAllCalendarNames()
    }
    
    private func buildPrompt(content: String, calendarNames: [String]) async throws -> String {
        await promptViewModel.getPromptContent()
            .replacingOccurrences(of: "CALENDAR_NAMES_LIST", with: calendarNames.isEmpty ? "Default Calendar" : calendarNames.joined(separator: ", "))
            .replacingOccurrences(of: "PLACEHOLDER_TEXT", with: content)
    }
} 
//
//  EventParsingService.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-20.
//

import Foundation
import OSLog

enum EventParsingError: LocalizedError {
    case invalidContent
    case llmProcessingFailed
    case eventParsingFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidContent:
            return NSLocalizedString("invalid_content", comment: "")
        case .llmProcessingFailed:
            return NSLocalizedString("llm_processing_failed", comment: "")
        case .eventParsingFailed:
            return NSLocalizedString("event_parsing_failed", comment: "")
        }
    }
}

actor EventParsingService {
    private let logger: Logger
    private let llmService: LLMService
    private let promptViewModel: PromptViewModel
    private let calendarManager: CalendarManager
    
    nonisolated init(
        logger: Logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "ScheduleSage", category: "EventParsingService"),
        llmService: LLMService = .shared,
        promptViewModel: PromptViewModel,
        calendarManager: CalendarManager = CalendarManager()
    ) {
        self.logger = logger
        self.llmService = llmService
        self.promptViewModel = promptViewModel
        self.calendarManager = calendarManager
    }
    
    func parseContent(_ content: String) async throws -> CalendarEvent {
        logger.info("Starting content parsing process")
        
        // 获取日历名称
        let calendarNames = try await getCalendarNames()
        
        // 构建提示词
        let prompt = try await buildPromptWithContent(content, calendarNames: calendarNames)
        logger.debug("Built prompt with calendar names")
        
        // 调用 LLM 服务
        let response = try await llmService.chat(content: prompt)
        logger.debug("Received LLM response")
        
        // 解析事件
        guard let event = CalendarEvent.from(llmResponse: response.content, logger: logger) else {
            logger.error("Failed to parse event from LLM response")
            throw EventParsingError.eventParsingFailed
        }
        
        logger.info("Successfully parsed content into calendar event")
        return event
    }
    
    private func getCalendarNames() async throws -> [String] {
        guard try await calendarManager.requestAccess() else {
            logger.error("Calendar access denied")
            return []
        }
        
        let names = calendarManager.getAllCalendarNames()
        logger.debug("Retrieved calendar names: \(names)")
        return names
    }
    
    private func buildPromptWithContent(_ content: String, calendarNames: [String]) async throws -> String {
        let basePrompt = await promptViewModel.getPromptContent()
        let calendarList = calendarNames.isEmpty ? "Default Calendar" : calendarNames.joined(separator: ", ")
        
        return basePrompt
            .replacingOccurrences(of: "CALENDAR_NAMES_LIST", with: calendarList)
            .replacingOccurrences(of: "PLACEHOLDER_TEXT", with: content)
    }
} 
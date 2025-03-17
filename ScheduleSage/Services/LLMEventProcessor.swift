//
//  LLMEventProcessor.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-20.
//

import Foundation

/// 处理自然语言输入并转换为日历事件的协议
public protocol LLMEventProcessor {
    /// 处理输入内容并生成日历事件
    /// - Parameter content: 需要处理的自然语言文本
    /// - Returns: 解析出的日历事件数组
    /// - Throws: LLMEventProcessorError 类型的错误
    func processContent(_ content: String) async throws -> [CalendarEvent]
}

/// LLM 事件处理器可能抛出的错误
public enum LLMEventProcessorError: LocalizedError {
    /// LLM 响应无效
    case invalidResponse
    /// 处理过程中发生错误
    case processingFailed(Error)
    /// 解析响应失败
    case parsingFailed
    /// 缺少必需字段
    case missingRequiredFields([String])
    /// 需要会员权限
    case requiresPremium
    
    public var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return NSLocalizedString("llm_invalid_response", comment: "")
        case .processingFailed(let error):
            return error.localizedDescription
        case .parsingFailed:
            return NSLocalizedString("llm_missing_fields", comment: "")
        case .missingRequiredFields(_):
            return NSLocalizedString("llm_missing_fields", comment: "")
        case .requiresPremium:
            return NSLocalizedString("premium_required", comment: "")
        }
    }
}

/// LLM 事件处理器的默认实现
public final class DefaultLLMEventProcessor: LLMEventProcessor {
    // MARK: - Dependencies
    
    private let logger: LoggerService
    private let llmService: LLMService
    private let promptViewModel: PromptViewModel
    private let calendarManager: CalendarManager
    
    // MARK: - Initialization
    
    /// 创建一个新的 LLM 事件处理器
    /// - Parameters:
    ///   - llmService: LLM 服务实例
    ///   - promptViewModel: 提示词视图模型
    ///   - calendarManager: 日历管理器
    ///   - logger: 日志记录器
    public init(
        llmService: LLMService = .shared,
        promptViewModel: PromptViewModel,
        calendarManager: CalendarManager = CalendarManager(),
        logger: LoggerService = .makeCompatible(category: "LLMEventProcessor")
    ) {
        self.llmService = llmService
        self.promptViewModel = promptViewModel
        self.calendarManager = calendarManager
        self.logger = logger
    }
    
    // MARK: - Public Methods
    
    /// 处理自然语言输入并生成日历事件
    /// - Parameter content: 需要处理的文本内容
    /// - Returns: 解析出的日历事件数组
    /// - Throws: LLMEventProcessorError 类型的错误
    /// - Complexity: O(n), n 为输入文本的长度
    public func processContent(_ content: String) async throws -> [CalendarEvent] {
        logger.info("Processing content with LLM, content: \(content)")
        
        // 检查会员权限 - 使用 checkPremiumAccess 替代直接检查 isPremium
        guard try await IAPService.shared.checkPremiumAccess() else {
            logger.info("Premium required for LLM processing")
            throw LLMEventProcessorError.requiresPremium
        }
        
        let calendarNames = await fetchAvailableCalendarNames()
        logger.info("Calendar names: \(calendarNames)")
        let prompt = try await buildPrompt(forContent: content, withCalendars: calendarNames)
        logger.debug("Prompt: \(prompt.prefix(100))")
        let response = try await llmService.chat(with: prompt)
        
        do {
            guard let events = CalendarEvent.from(llmResponse: response.content, logger: logger) else {
                logger.error("Failed to parse LLM response into calendar events")
                throw LLMEventProcessorError.parsingFailed
            }
            
            // 过滤出有效的事件，而不是抛出异常
            let validEvents = events.filter { event in
                do {
                    try validateRequiredFields(in: event)
                    return true
                } catch {
                    logger.warning("Skipping invalid event: \(event.title). Reason: \(error.localizedDescription)")
                    return false
                }
            }
            
            if validEvents.isEmpty && !events.isEmpty {
                logger.error("All events were invalid")
                throw LLMEventProcessorError.parsingFailed
            }
            
            logger.info("Successfully processed \(validEvents.count) valid events out of \(events.count) total")
            return validEvents
            
        } catch let decodingError as DecodingError {
            logger.error("JSON decoding error: \(decodingError.localizedDescription)")
            throw LLMEventProcessorError.parsingFailed
        } catch {
            logger.error("Unexpected error: \(error.localizedDescription)")
            throw LLMEventProcessorError.processingFailed(error)
        }
    }
    
    // MARK: - Private Methods
    
    /// 验证事件是否包含所有必需字段
    /// - Parameter event: 需要验证的日历事件
    /// - Throws: 如果缺少必需字段，抛出 missingRequiredFields 错误
    private func validateRequiredFields(in event: CalendarEvent) throws {
        var missingFields: [String] = []
        
        if event.title.isEmpty {
            missingFields.append(CalendarEvent.displayName(for: "title"))
        }
        if event.startDate.isEmpty {
            missingFields.append(CalendarEvent.displayName(for: "startDate"))
        }
        
        guard missingFields.isEmpty else {
            logger.error("Missing required fields: \(missingFields.joined(separator: ", "))")
            throw LLMEventProcessorError.missingRequiredFields(missingFields)
        }
    }
    
    /// 获取可用的日历名称列表
    /// - Returns: 日历名称数组
    private func fetchAvailableCalendarNames() async -> [String] {
        guard (try? await calendarManager.requestAccess()) == true else {
            logger.warning("Calendar access denied")
            return []
        }
        return calendarManager.getAllCalendarNames()
    }
    
    /// 获取当前时区信息的格式化字符串
    /// - Returns: 格式化的时区信息，例如："Asia/Shanghai (CST), UTC+08:00"
    private func formatCurrentTimezoneInfo() -> String {
        let timezone = TimeZone.current
        let offset = timezone.secondsFromGMT()
        let hours = abs(offset) / 3600
        let minutes = (abs(offset) % 3600) / 60
        
        var result = timezone.identifier
        if let abbreviation = timezone.abbreviation() {
            result += " (\(abbreviation))"
        }
        result += ", UTC"
        result += offset >= 0 ? "+" : "-"
        result += String(format: "%02d:%02d", hours, minutes)
        
        return result
    }
    
    /// 构建完整的提示词
    /// - Parameters:
    ///   - content: 用户输入的内容
    ///   - calendarNames: 可用的日历名称列表
    /// - Returns: 处理后的完整提示词
    private func buildPrompt(forContent content: String, withCalendars calendarNames: [String]) async throws -> String {
        let userContext = makeUserContextJSON()
        
        return await promptViewModel.getPromptContent()
            .replacingOccurrences(of: "CALENDAR_NAMES_LIST", with: calendarNames.isEmpty ? "Default Calendar" : calendarNames.joined(separator: ", "))
            .replacingOccurrences(of: "CURRENT_TIMEZONE", with: formatCurrentTimezoneInfo())
            .replacingOccurrences(of: "PLACEHOLDER_TEXT", with: content)
            .replacingOccurrences(of: "USER_CONTEXT", with: userContext)
    }
    
    /// 创建用户上下文的 JSON 字符串
    /// - Returns: 包含用户时区、日期等信息的 JSON 字符串
    private func makeUserContextJSON() -> String {
        let calendar = Calendar.current
        let timeZone = TimeZone.current
        let now = Date()
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "Z"
        
        let userContext: [String: String] = [
            "timeZone": timeZone.identifier,
            "timeZoneOffset": dateFormatter.string(from: now),
            "currentYear": String(calendar.component(.year, from: now)),
            "currentMonth": String(calendar.component(.month, from: now)),
            "currentDay": String(calendar.component(.day, from: now)),
            "currentWeekday": String(calendar.component(.weekday, from: now)),
            "locale": Locale.current.identifier,
            "calendar": calendar.identifier.description,
            "timestamp": String(Int(now.timeIntervalSince1970))
        ]
        
        do {
            let jsonData = try JSONSerialization.data(
                withJSONObject: userContext,
                options: [.prettyPrinted, .sortedKeys]
            )
            return String(data: jsonData, encoding: .utf8) ?? "{}"
        } catch {
            logger.error("Failed to create user context JSON: \(error.localizedDescription)")
            return "{}"
        }
    }
} 

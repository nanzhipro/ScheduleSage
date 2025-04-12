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
    private let calendarManager: CalendarManager
    
    // MARK: - Initialization
    
    /// 创建一个新的 LLM 事件处理器
    /// - Parameters:
    ///   - llmService: LLM 服务实例
    ///   - calendarManager: 日历管理器
    ///   - logger: 日志记录器
    public init(
        llmService: LLMService = .shared,
        calendarManager: CalendarManager = CalendarManager(),
        logger: LoggerService = .makeCompatible(category: "LLMEventProcessor")
    ) {
        self.llmService = llmService
        self.calendarManager = calendarManager
        self.logger = logger
    }
    
    // 保留向后兼容的初始化方法，但不再依赖PromptViewModel
    @available(*, deprecated, message: "使用不带PromptViewModel的初始化方法")
    public convenience init(
        llmService: LLMService = .shared,
        promptViewModel: Any,
        calendarManager: CalendarManager = CalendarManager(),
        logger: LoggerService = .makeCompatible(category: "LLMEventProcessor")
    ) {
        self.init(
            llmService: llmService,
            calendarManager: calendarManager,
            logger: logger
        )
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
        
        // 获取可用日历名称
        let calendarNames = await fetchAvailableCalendarNames()
        logger.info("Calendar names: \(calendarNames)")
        
        // 构建请求参数
        let calendarNamesList = calendarNames.isEmpty ? "Default Calendar" : calendarNames.joined(separator: ", ")
        let userContext = makeUserContextJSON()
        
        // 调用LLM服务
        do {
            let response = try await llmService.chat(
                calendarNamesList: calendarNamesList,
                userContext: userContext,
                placeholderText: content
            )
            
            // 解析响应
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
        if event.endDate.isEmpty {
            missingFields.append(CalendarEvent.displayName(for: "endDate"))
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

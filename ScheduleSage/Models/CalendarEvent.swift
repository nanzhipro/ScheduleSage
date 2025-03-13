//
//  CalendarEvent.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-20.
//

import Foundation
import OSLog

/// 日历事件模型，从 LLM 响应中解析，对应的 JSON 结构如下：
/// ```json
/// {
///   "title": "值",
///   "location": "值",
///   "notes": "值",
///   "startDate": "值",
///   "endDate": "值",
///   "url": "值",
///   "calendar": "值",
///   "status": "值",
///   "eventIdentifier": "直接生成的UUID",
///   "remarks": "如有不确定的信息，请在此注明"
/// }
/// ```
public struct CalendarEvent: Codable, Identifiable {
    // MARK: - Properties
    
    public var id: String { eventIdentifier }  // 实现 Identifiable 协议
    let title: String
    let location: String
    let notes: String
    let startDate: String
    let endDate: String
    let url: String
    let calendar: String
    let status: String
    let eventIdentifier: String
    let remarks: String
    
    // MARK: - Field Display Names
    
    static let fieldDisplayNames: [String: String] = [
        "title": NSLocalizedString("event_field_title", comment: "Event title field name"),
        "startDate": NSLocalizedString("event_field_start_date", comment: "Event start date field name"),
        "endDate": NSLocalizedString("event_field_end_date", comment: "Event end date field name"),
        "location": NSLocalizedString("event_field_location", comment: "Event location field name"),
        "notes": NSLocalizedString("event_field_notes", comment: "Event notes field name"),
        "url": NSLocalizedString("event_field_url", comment: "Event URL field name"),
        "calendar": NSLocalizedString("event_field_calendar", comment: "Event calendar field name")
    ]
    
    /// 获取字段的显示名称
    static func displayName(for field: String) -> String {
        return fieldDisplayNames[field] ?? field
    }
    
    // MARK: - Date Formatters
    
    private static let dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.timeZone = .current
        formatter.locale = .current
        formatter.doesRelativeDateFormatting = true  // 启用相对日期格式化
        return formatter
    }()
    
    /// 格式化后的时间显示
    public var time: String {
        guard let start = parsedStartDate,
              let end = parsedEndDate else {
            return ""
        }
        
        return DateFormatters.formatDateRange(start: start, end: end)
    }
    
    // MARK: - Coding Keys
    
    enum CodingKeys: String, CodingKey {
        case title
        case location
        case notes
        case startDate
        case endDate
        case url
        case calendar
        case status
        case eventIdentifier
        case remarks
    }
    
    // MARK: - Initialization
    
    public init(
        title: String,
        location: String,
        notes: String,
        startDate: String,
        endDate: String,
        url: String,
        calendar: String,
        status: String,
        eventIdentifier: String = UUID().uuidString,
        remarks: String
    ) {
        self.title = title
        self.location = location
        self.notes = notes
        self.startDate = startDate
        self.endDate = endDate
        self.url = url
        self.calendar = calendar
        self.status = status
        self.eventIdentifier = eventIdentifier
        self.remarks = remarks
    }
}

// MARK: - JSON Conversion
extension CalendarEvent {
    /// 从 LLM 响应内容创建事件模型
    public static func from(llmResponse content: String, logger: LoggerService) -> [CalendarEvent]? {
        do {
            logger.info("Parsing LLM response: \(content)")
            // 尝试将字符串解析为 JSON 数据
            guard let jsonData = content.data(using: .utf8) else {
                logger.error("Failed to convert string to data: \(content)")
                return nil
            }
            
            let decoder = JSONDecoder()
            
            // 首先尝试解析为数组
            if let events = try? decoder.decode([CalendarEvent].self, from: jsonData) {
                return events
            }
            
            // 如果不是数组，尝试解析为单个对象并将其包装在数组中
            if let event = try? decoder.decode(CalendarEvent.self, from: jsonData) {
                return [event]
            }
            
            logger.error("Failed to decode calendar event(s) from JSON")
            return nil
            
        } catch {
            logger.error("Failed to decode calendar event: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// 将事件模型转换为 JSON 字符串
    public func toJSONString(logger: LoggerService) -> String? {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            
            let jsonData = try encoder.encode(self)
            return String(data: jsonData, encoding: .utf8)
            
        } catch {
            logger.error("Failed to encode calendar event: \(error.localizedDescription)")
            return nil
        }
    }
}

// MARK: - Date Conversion
extension CalendarEvent {
    /// 获取格式化的开始日期
    public var parsedStartDate: Date? {
        // 使用标准格式化器解析日期
        let formatter = DateFormatter.standardFormatter
        guard let date = formatter.date(from: startDate) else {
            return nil
        }
        return date
    }
    
    /// 获取格式化的结束日期
    public var parsedEndDate: Date? {
        // 使用标准格式化器解析日期
        let formatter = DateFormatter.standardFormatter
        guard let date = formatter.date(from: endDate) else {
            return nil
        }
        return date
    }
}

// MARK: - Date Formatter
private extension DateFormatter {
    /// 用于解析日期字符串的格式化器
    static let standardFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone.current  // 使用当前时区
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
} 
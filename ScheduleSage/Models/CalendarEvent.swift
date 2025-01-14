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
    
    // MARK: - Computed Properties
    
    /// 格式化后的时间显示
    public var time: String {
        guard let start = parsedStartDate,
              let end = parsedEndDate else {
            return ""
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
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
    public static func from(llmResponse content: String, logger: Logger) -> CalendarEvent? {
        do {
            // 尝试将字符串解析为 JSON 数据
            guard let jsonData = content.data(using: .utf8) else {
                logger.error("Failed to convert string to data: \(content)")
                return nil
            }
            
            // 解码 JSON 数据为事件模型
            let decoder = JSONDecoder()
            let event = try decoder.decode(CalendarEvent.self, from: jsonData)
            return event
            
        } catch {
            logger.error("Failed to decode calendar event: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// 将事件模型转换为 JSON 字符串
    public func toJSONString(logger: Logger) -> String? {
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
        DateFormatter.iso8601Full.date(from: startDate)
    }
    
    /// 获取格式化的结束日期
    public var parsedEndDate: Date? {
        DateFormatter.iso8601Full.date(from: endDate)
    }
}

// MARK: - Date Formatter
private extension DateFormatter {
    static let iso8601Full: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
} 
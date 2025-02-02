//
//  DateFormatters.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-21.
//

import Foundation

/// 日期格式化工具
/// 统一管理应用中的日期格式化逻辑
public enum DateFormatters {
    /// 标准日期格式化器
    /// 用于解析 "yyyy-MM-dd HH:mm:ss" 格式的日期字符串
    public static let standard: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    /// 显示用日期格式化器
    /// 用于界面显示，支持相对日期和本地化
    public static let display: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.timeZone = .current
        formatter.locale = .current
        formatter.doesRelativeDateFormatting = false
        return formatter
    }()
    
    /// 格式化日期范围
    /// - Parameters:
    ///   - start: 开始日期
    ///   - end: 结束日期
    /// - Returns: 格式化后的日期范围字符串
    public static func formatDateRange(start: Date, end: Date) -> String {
        let startStr = display.string(from: start)
        let endStr = display.string(from: end)
        
        return String(
            format: NSLocalizedString(
                "event_time_range_format",
                comment: "Format string for event time range. Example: '今天 14:30 至 16:30'"
            ),
            startStr,
            endStr
        )
    }
    
    /// 解析日期字符串
    /// - Parameter dateString: 日期字符串
    /// - Returns: 解析后的 Date 对象，如果解析失败则返回 nil
    public static func parse(_ dateString: String) -> Date? {
        standard.date(from: dateString)
    }
} 
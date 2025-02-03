//
//  ContentPreprocessor.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024.03.14.
//

import Foundation
import NaturalLanguage

// MARK: - ContentPreprocessorError
public enum ContentPreprocessorError: LocalizedError {
    case noTimeInformation
    case invalidContent
    
    public var errorDescription: String? {
        switch self {
        case .noTimeInformation:
            return NSLocalizedString("no_time_information_found", comment: "")
        case .invalidContent:
            return NSLocalizedString("invalid_content", comment: "")
        }
    }
}

// MARK: - ContentPreprocessor Protocol
public protocol ContentPreprocessor {
    func containsTimeInformation(_ content: String) async throws -> Bool
}

// MARK: - DefaultContentPreprocessor
public final class DefaultContentPreprocessor: ContentPreprocessor {
    private let dateDetector: DateDetector
    private let nlProcessor: NLProcessor
    
    public init(dateDetector: DateDetector = DefaultDateDetector(),
                nlProcessor: NLProcessor = DefaultNLProcessor()) {
        self.dateDetector = dateDetector
        self.nlProcessor = nlProcessor
    }
    
    public func containsTimeInformation(_ content: String) async throws -> Bool {
        // 1. 使用正则表达式检查日期时间格式
        if dateDetector.containsDateTimePatterns(in: content) {
            return true
        }
        
        // 2. 使用自然语言处理检查时间相关词汇
        return await nlProcessor.containsTimeRelatedTokens(in: content)
    }
}

// MARK: - DateDetector Protocol
public protocol DateDetector {
    func containsDateTimePatterns(in content: String) -> Bool
}

// MARK: - DefaultDateDetector
public final class DefaultDateDetector: DateDetector {
    private let patterns: [String] = [
        // 标准日期格式
        "\\d{4}[-/.]\\d{1,2}[-/.]\\d{1,2}",
        // 12/24小时制时间
        "\\d{1,2}:\\d{2}(?::\\d{2})?(?:\\s*[AaPp][Mm])?",
        // 月份名称
        "(?:Jan(?:uary)?|Feb(?:ruary)?|Mar(?:ch)?|Apr(?:il)?|May|Jun(?:e)?|Jul(?:y)?|Aug(?:ust)?|Sep(?:tember)?|Oct(?:ober)?|Nov(?:ember)?|Dec(?:ember)?)\\s+\\d{1,2}",
        // 中文日期时间
        "[年月日时分秒]",
        // 日语日期时间
        "[年月日時分秒]"
    ]
    
    public init() {}
    
    public func containsDateTimePatterns(in content: String) -> Bool {
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let range = NSRange(content.startIndex..<content.endIndex, in: content)
                if regex.firstMatch(in: content, range: range) != nil {
                    return true
                }
            }
        }
        return false
    }
}

// MARK: - NLProcessor Protocol
public protocol NLProcessor {
    func containsTimeRelatedTokens(in content: String) async -> Bool
}

// MARK: - DefaultNLProcessor
public final class DefaultNLProcessor: NLProcessor {
    private let timeRelatedWords: Set<String> = [
        // 英文
        "today", "tomorrow", "yesterday", "morning", "afternoon", "evening", "night",
        "monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday",
        "week", "month", "year", "schedule", "appointment", "meeting",
        // 中文
        "今天", "明天", "昨天", "上午", "下午", "晚上", "早上",
        "周一", "周二", "周三", "周四", "周五", "周六", "周日",
        "星期一", "星期二", "星期三", "星期四", "星期五", "星期六", "星期日",
        "周末", "下周", "本周", "月", "年", "日程", "会议",
        // 日文
        "今日", "明日", "昨日", "午前", "午後", "朝", "夜",
        "月曜日", "火曜日", "水曜日", "木曜日", "金曜日", "土曜日", "日曜日",
        "週末", "来週", "今週", "月", "年", "予定", "会議"
    ]
    
    public init() {}
    
    public func containsTimeRelatedTokens(in content: String) async -> Bool {
        let tagger = NLTagger(tagSchemes: [.tokenType, .language])
        tagger.string = content.lowercased()
        
        var containsTimeWord = false
        tagger.enumerateTags(in: content.startIndex..<content.endIndex,
                            unit: .word,
                            scheme: .tokenType) { tag, tokenRange in
            let token = String(content[tokenRange]).lowercased()
            if timeRelatedWords.contains(token) {
                containsTimeWord = true
                return false
            }
            return true
        }
        
        return containsTimeWord
    }
}

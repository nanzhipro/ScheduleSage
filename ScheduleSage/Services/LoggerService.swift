//
//  LoggerService.swift
//  ScheduleSage
//
//  Created by CursorAI on 2023-12-20.
//

import CocoaLumberjackSwift
import Foundation
import OSLog

// MARK: - 日志记录协议
public protocol LoggerProtocol {
  func setupLogger()
  func logDebug(_ message: String)
  func logInfo(_ message: String)
  func logWarn(_ message: String)
  func logError(_ message: String)
}

// MARK: - 自定义日志格式器
private class CustomLogFormatter: NSObject, DDLogFormatter {
  private let dateFormatter: DateFormatter

  override init() {
    dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
    super.init()
  }

  func format(message logMessage: DDLogMessage) -> String? {
    let timestamp = dateFormatter.string(from: logMessage.timestamp)

    let logLevel: String
    switch logMessage.flag {
    case .error:
      logLevel = "ERROR"
    case .warning:
      logLevel = "WARN"
    case .info:
      logLevel = "INFO"
    case .debug:
      logLevel = "DEBUG"
    default:
      logLevel = "VERBOSE"
    }
    
    return "\(timestamp) [\(logLevel)] - \(logMessage.message)"
  }
}

// MARK: - 日志记录服务
/// 提供与系统Logger兼容的日志记录服务，支持文件日志和控制台日志
public final class LoggerService {
    // MARK: - 属性
    private let category: String
    private let subsystem: String
    private let fileLogger: DDFileLogger
    private static var isConfigured = false
    
    // MARK: - 初始化
    /// 创建一个新的日志记录服务实例
    /// - Parameters:
    ///   - subsystem: 子系统标识符，通常为应用的Bundle ID
    ///   - category: 日志类别，通常为类名或模块名
    public init(subsystem: String, category: String) {
        self.subsystem = subsystem
        self.category = category
        self.fileLogger = DDFileLogger()
        
        // 确保全局配置只执行一次
        Self.configureLoggingIfNeeded()
    }
    
    // MARK: - 日志方法
    /// 记录调试级别日志
    /// - Parameter message: 日志消息
    public func debug(_ message: String) {
        DDLogDebug("[\(category)] \(message)")
    }
    
    /// 记录信息级别日志
    /// - Parameter message: 日志消息
    public func info(_ message: String) {
        DDLogInfo("[\(category)] \(message)")
    }
    
    /// 记录通知级别日志
    /// - Parameter message: 日志消息
    public func notice(_ message: String) {
        DDLogInfo("[\(category)] NOTICE: \(message)")
    }
    
    /// 记录警告级别日志
    /// - Parameter message: 日志消息
    public func warning(_ message: String) {
        DDLogWarn("[\(category)] \(message)")
    }
    
    /// 记录错误级别日志
    /// - Parameter message: 日志消息
    public func error(_ message: String) {
        DDLogError("[\(category)] \(message)")
    }
    
    /// 记录严重错误级别日志
    /// - Parameter message: 日志消息
    public func critical(_ message: String) {
        DDLogError("[\(category)] CRITICAL: \(message)")
    }
    
    /// 记录故障级别日志
    /// - Parameter message: 日志消息
    public func fault(_ message: String) {
        DDLogError("[\(category)] FAULT: \(message)")
    }
    
    // MARK: - 工厂方法
    /// 创建一个新的日志记录服务实例
    /// - Parameters:
    ///   - subsystem: 子系统标识符，默认为应用的Bundle ID
    ///   - category: 日志类别
    /// - Returns: 配置好的LoggerService实例
    public static func logger(subsystem: String = Bundle.main.bundleIdentifier ?? "ScheduleSage", category: String) -> LoggerService {
        return LoggerService(subsystem: subsystem, category: category)
    }
    
    // MARK: - 私有方法
    private static func configureLoggingIfNeeded() {
        guard !isConfigured else { return }
        
        // 配置控制台日志
        DDLog.add(DDOSLogger.sharedInstance)
        DDOSLogger.sharedInstance.logFormatter = CustomLogFormatter()
        
        // 配置文件日志
        let fileLogger = configureFileLogger()
        DDLog.add(fileLogger)
        
        isConfigured = true
    }
    
    private static func configureFileLogger() -> DDFileLogger {
        let fileManager = FileManager.default
        let logDirectoryURL: URL
        
        if let appSupportDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            logDirectoryURL = appSupportDirectory.appendingPathComponent("ScheduleSage")
        } else {
            logDirectoryURL = URL(fileURLWithPath: "./ScheduleSage")
        }
        
        do {
            try fileManager.createDirectory(at: logDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            DDLogError("无法创建日志目录: \(error.localizedDescription)")
        }
        
        let logFileManager = DDLogFileManagerDefault(logsDirectory: logDirectoryURL.path)
        let fileLogger = DDFileLogger(logFileManager: logFileManager)
        fileLogger.maximumFileSize = 1024 * 1024 * 10  // 10MB
        fileLogger.logFileManager.maximumNumberOfLogFiles = 7
        fileLogger.logFormatter = CustomLogFormatter()
        
        return fileLogger
    }
}

// MARK: - OSLog.Logger 兼容扩展
extension LoggerService {
    /// 创建一个与OSLog.Logger接口兼容的LoggerService实例
    /// - Parameters:
    ///   - subsystem: 子系统标识符，默认为应用的Bundle ID
    ///   - category: 日志类别
    /// - Returns: 配置好的LoggerService实例
    public static func makeCompatible(subsystem: String = Bundle.main.bundleIdentifier ?? "ScheduleSage", category: String) -> LoggerService {
        return logger(subsystem: subsystem, category: category)
    }
}

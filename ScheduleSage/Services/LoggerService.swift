import CocoaLumberjackSwift
import Foundation

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

    let fileName = (logMessage.fileName as NSString).lastPathComponent
    return "\(timestamp) [\(logLevel)] [\(fileName):\(logMessage.line)] - \(logMessage.message)"
  }
}

// MARK: - 日志记录类
public final class LoggerService: LoggerProtocol {
  private let fileLogger: DDFileLogger

  public init() {
    self.fileLogger = DDFileLogger()
    setupLogger()
  }

  public func setupLogger() {
    DDLog.add(DDOSLogger.sharedInstance)
    DDOSLogger.sharedInstance.logFormatter = CustomLogFormatter()
    DDLog.add(fileLogger)
    fileLogger.logFormatter = CustomLogFormatter()
    _ = LoggerService.configureFileLogger()
  }

  public func logDebug(_ message: String) {
    DDLogDebug(message)
  }

  public func logInfo(_ message: String) {
    DDLogInfo(message)
  }

  public func logWarn(_ message: String) {
    DDLogWarn(message)
  }

  public func logError(_ message: String) {
    DDLogError(message)
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
    fileLogger.maximumFileSize = 1024 * 1024 * 10
    fileLogger.logFileManager.maximumNumberOfLogFiles = 7

    return fileLogger
  }
}

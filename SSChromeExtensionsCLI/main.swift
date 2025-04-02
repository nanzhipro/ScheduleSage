//
//  main.swift
//  SSChromeExtensionsCLI
//
//  Created by 南朋友 on 2025/4/2.
//

import Foundation

/// Chrome扩展通信错误
enum ChromeExtensionError: Error, CustomStringConvertible {
    case invalidMessageLength(got: Int, expected: Int = 4)
    case messageSizeTooLarge(size: UInt32)
    case incompleteMessageData(got: Int, expected: Int)
    case invalidJSONFormat
    case invalidURL(String)
    case fileWriteError(String)
    
    var description: String {
        switch self {
        case .invalidMessageLength(let got, let expected):
            return "消息长度无效: 期望\(expected)字节，实际获得\(got)字节"
        case .messageSizeTooLarge(let size):
            return "消息尺寸过大: \(size)字节"
        case .incompleteMessageData(let got, let expected):
            return "消息数据不完整: 期望\(expected)字节，实际获得\(got)字节"
        case .invalidJSONFormat:
            return "无效的JSON格式"
        case .invalidURL(let url):
            return "无效的URL格式: \(url)"
        case .fileWriteError(let path):
            return "文件写入错误: \(path)"
        }
    }
}

/// Chrome扩展与应用程序之间的通信处理器
struct ChromeExtensionHandler {
    /// 最大允许的消息尺寸 (10MB)
    private static let maxMessageSize: UInt32 = 10_000_000
    
    /// 日志文件名
    private static let urlLogFilename = "schedulesage_urls.txt"
    private static let errorLogFilename = "schedulesage_errors.txt"
    
    /// 时间戳格式器
    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
    
    /// 处理Chrome扩展发送的消息
    static func processMessage() {
        do {
            let messageData = try readMessageFromStdin()
            let url = try parseURL(from: messageData)
            try logURL(url)
            
            // 可以在这里添加代码通知ScheduleSage应用程序
            
            sendSuccessResponse()
        } catch {
            handleError(error)
        }
    }
    
    /// 从标准输入读取消息
    /// - 返回值: 消息数据
    /// - 抛出: 读取错误
    private static func readMessageFromStdin() throws -> Data {
        // 读取长度字段 (4字节)
        let lengthData = FileHandle.standardInput.readData(ofLength: 4)
        
        // 验证长度数据
        if lengthData.isEmpty {
            exit(0) // 标准输入已关闭
        }
        
        guard lengthData.count == 4 else {
            throw ChromeExtensionError.invalidMessageLength(got: lengthData.count)
        }
        
        // 解析消息长度 (小端字节序)
        let length = lengthData.withUnsafeBytes { bytes in
            return bytes.load(as: UInt32.self).littleEndian
        }
        
        // 验证消息长度合理性
        guard length > 0, length < maxMessageSize else {
            throw ChromeExtensionError.messageSizeTooLarge(size: length)
        }
        
        // 读取消息内容
        let messageData = FileHandle.standardInput.readData(ofLength: Int(length))
        
        // 验证消息完整性
        guard messageData.count == Int(length) else {
            throw ChromeExtensionError.incompleteMessageData(got: messageData.count, expected: Int(length))
        }
        
        return messageData
    }
    
    /// 从消息数据中解析URL
    /// - 参数 data: 消息数据
    /// - 返回值: 解析出的URL字符串
    /// - 抛出: 解析错误
    private static func parseURL(from data: Data) throws -> String {
        // 解析JSON
        guard let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let url = jsonObject["url"] as? String else {
            throw ChromeExtensionError.invalidJSONFormat
        }
        
        // 验证URL格式
        guard URL(string: url) != nil else {
            throw ChromeExtensionError.invalidURL(url)
        }
        
        return url
    }
    
    /// 将URL记录到日志文件
    /// - 参数 url: 要记录的URL
    /// - 抛出: 写入错误
    private static func logURL(_ url: String) throws {
        let timestamp = timestampFormatter.string(from: Date())
        let logEntry = "[\(timestamp)] \(url)\n"
        
        let logPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(urlLogFilename)
        
        try appendToFile(at: logPath, content: logEntry)
    }
    
    /// 向文件追加内容
    /// - 参数:
    ///   - path: 文件路径
    ///   - content: 要追加的内容
    /// - 抛出: 写入错误
    private static func appendToFile(at path: URL, content: String) throws {
        guard let data = content.data(using: .utf8) else { return }
        
        if FileManager.default.fileExists(atPath: path.path) {
            let fileHandle = try FileHandle(forWritingTo: path)
            defer { fileHandle.closeFile() }
            
            fileHandle.seekToEndOfFile()
            fileHandle.write(data)
        } else {
            try data.write(to: path, options: .atomic)
        }
    }
    
    /// 发送成功响应
    private static func sendSuccessResponse() {
        sendResponse(["status": "success"])
    }
    
    /// 处理错误
    /// - 参数 error: 捕获的错误
    private static func handleError(_ error: Error) {
        logError(error)
        
        let errorMessage: String
        if let chromeError = error as? ChromeExtensionError {
            errorMessage = chromeError.description
        } else {
            errorMessage = error.localizedDescription
        }
        
        sendResponse([
            "status": "error",
            "error": errorMessage
        ])
    }
    
    /// 记录错误到日志文件
    /// - 参数 error: 要记录的错误
    private static func logError(_ error: Error) {
        let timestamp = timestampFormatter.string(from: Date())
        let errorMessage = "[\(timestamp)] Error: \(error)\n"
        
        let errorLogPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(errorLogFilename)
        
        do {
            try appendToFile(at: errorLogPath, content: errorMessage)
        } catch {
            // 如果错误日志无法写入，我们无法做更多处理
        }
    }
    
    /// 向Chrome扩展发送响应
    /// - 参数 responseDict: 响应数据字典
    private static func sendResponse(_ responseDict: [String: Any]) {
        do {
            // 序列化响应
            let responseData = try JSONSerialization.data(withJSONObject: responseDict)
            
            // 获取长度并转为小端字节序
            let length = UInt32(responseData.count).littleEndian
            
            // 写入长度 (4字节)
            withUnsafeBytes(of: length) { bytes in
                FileHandle.standardOutput.write(Data(bytes))
            }
            
            // 写入响应内容
            FileHandle.standardOutput.write(responseData)
            
            // 刷新输出缓冲区
            fflush(stdout)
        } catch {
            // 响应发送失败，只能记录错误
            logError(error)
        }
    }
}

// 执行消息处理
ChromeExtensionHandler.processMessage()


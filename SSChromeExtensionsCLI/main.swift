//
//  main.swift
//  SSChromeExtensionsCLI
//
//  Created by CursorAI on 2024/4/2.
//

import AppKit
import Foundation

/// Chrome扩展通信错误
enum ChromeExtensionError: Error, CustomStringConvertible {
  case invalidMessageLength(got: Int, expected: Int = 4)
  case messageSizeTooLarge(size: UInt32)
  case incompleteMessageData(got: Int, expected: Int)
  case invalidJSONFormat
  case invalidURL(String)

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
    }
  }
}

/// Chrome扩展与应用程序之间的通信处理器
struct ChromeExtensionHandler {
  /// 最大允许的消息尺寸 (10MB)
  private static let maxMessageSize: UInt32 = 10_000_000

  /// 处理Chrome扩展发送的消息
  static func processMessage() {
    do {
      let messageData = try readMessageFromStdin()
      let url = try parseURL(from: messageData)

      // 在CLI中:
      guard let urlToSend = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
        throw ChromeExtensionError.invalidURL(url)
      }

      if let appURL = URL(string: "schedulesage://chromex?url=\(urlToSend)") {
        NSWorkspace.shared.open(appURL)
      }

      sendSuccessResponse()
    } catch {
      handleError(error)
    }
  }

  /// 从标准输入读取消息
  private static func readMessageFromStdin() throws -> Data {
    // 读取长度字段 (4字节)
    let lengthData = FileHandle.standardInput.readData(ofLength: 4)

    // 验证长度数据
    if lengthData.isEmpty {
      exit(0)
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
  private static func parseURL(from data: Data) throws -> String {
    // 解析JSON
    guard let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
      let url = jsonObject["url"] as? String
    else {
      throw ChromeExtensionError.invalidJSONFormat
    }

    // 验证URL格式
    guard URL(string: url) != nil else {
      throw ChromeExtensionError.invalidURL(url)
    }

    return url
  }

  /// 发送成功响应
  private static func sendSuccessResponse() {
    sendResponse(["status": "success"])
  }

  /// 处理错误
  private static func handleError(_ error: Error) {
    let errorMessage: String
    if let chromeError = error as? ChromeExtensionError {
      errorMessage = chromeError.description
    } else {
      errorMessage = error.localizedDescription
    }

    sendResponse([
      "status": "error",
      "error": errorMessage,
    ])
  }

  /// 向Chrome扩展发送响应
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
      // 如果发送响应失败，直接退出
      exit(1)
    }
  }
}

// 执行消息处理
ChromeExtensionHandler.processMessage()

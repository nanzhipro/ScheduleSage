//
//  main.swift
//  mcp-server
//
//  Created by CursorAI on 2025/4/6.
//

import Foundation
import MCP

/// 日志工具函数，用于打印带有时间戳和类型的日志信息
/// - Parameters:
///   - message: 日志消息内容
///   - type: 日志类型，例如 INFO, ERROR, WARNING 等
func log(_ message: String, type: String = "INFO") {
  let dateFormatter = DateFormatter()
  dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
  let timestamp = dateFormatter.string(from: Date())
  print("[\(timestamp)] [\(type)] \(message)")
}

/// 定义MCP服务器的错误类型，继承自Swift.Error
enum MCPServerError: Swift.Error {
  case toolError(String)

  var localizedDescription: String {
    switch self {
    case .toolError(let message):
      return "工具错误: \(message)"
    }
  }
}

/// 主程序功能类
struct MCPServerApp {
  /// 程序入口点
  static func run() async throws {
    log("启动 MCP 服务器...", type: "STARTUP")

    // 创建服务器实例
    let server = createServer()

    // 配置服务器处理程序
    await setupServerHandlers(server)

    // 创建标准输入/输出传输管道
    log("创建 stdio 传输管道...", type: "STARTUP")
    let transport = StdioTransport()

    // 启动服务器
    log("开始启动服务器...", type: "STARTUP")
    try await server.start(transport: transport)
    log("服务器启动成功，等待连接...", type: "STARTUP")

    // 等待用户输入来停止服务器
    log("服务器已启动并运行中. 按 Enter 键停止...", type: "INFO")
    await waitForUserEnterToShutdown()

    // 停止服务器
    // log("正在停止服务器...", type: "SHUTDOWN")
    // await server.stop()
    // log("服务器已成功停止", type: "SHUTDOWN")
  }

  /// 等待用户按下Enter键来触发关闭
  private static func waitForUserEnterToShutdown() async {
    // 从主线程读取标准输入
    await withCheckedContinuation { continuation in
      // 启动一个新线程来读取标准输入
      Thread.detachNewThread {
        // 等待任意输入
        _ = readLine()
        // 继续主程序的执行
        continuation.resume()
      }
    }
  }

  /// 创建并配置MCP服务器实例
  /// - Returns: 配置好的Server实例
  private static func createServer() -> Server {
    log("创建服务器实例...", type: "SETUP")

    // 设置服务器能力
    let capabilities = Server.Capabilities(
      // 禁用提示功能
      prompts: .init(),
      // 禁用资源功能
      resources: .init(),
      // 启用工具功能
      tools: Server.Capabilities.Tools()
    )

    // 创建并返回服务器实例
    return Server(
      name: "SimpleMCPServer",
      version: "1.0.0",
      capabilities: capabilities
    )
  }

  /// 为服务器配置各种处理程序
  /// - Parameter server: 要配置的服务器实例
  private static func setupServerHandlers(_ server: Server) async {
    log("配置服务器处理程序...", type: "SETUP")

    // 配置工具处理程序
    await setupToolHandlers(server)
  }

  /// 配置工具相关处理程序
  /// - Parameter server: 要配置的服务器实例
  private static func setupToolHandlers(_ server: Server) async {
    log("配置工具处理程序...", type: "SETUP")

    // 处理工具列表请求
    await server.withMethodHandler(ListTools.self) { _ in
      log("收到工具列表请求", type: "REQUEST")

      // 定义天气工具的输入参数
      let weatherInputSchema = Value.object([
        "properties": .object([
          "location": .object([
            "type": .string("string"),
            "description": .string("位置名称，如：北京、上海"),
          ]),
          "unit": .object([
            "type": .string("string"),
            "description": .string("温度单位：celsius 或 fahrenheit"),
            "default": .string("celsius"),
          ]),
        ]),
        "required": .array([.string("location")]),
      ])

      // 定义计算器工具的输入参数
      let calculatorInputSchema = Value.object([
        "properties": .object([
          "expression": .object([
            "type": .string("string"),
            "description": .string("数学表达式，如：2 + 2 * 3"),
          ])
        ]),
        "required": .array([.string("expression")]),
      ])

      // 定义天气工具
      let weatherTool = Tool(
        name: "weather",
        description: "获取指定位置的天气信息",
        inputSchema: weatherInputSchema
      )

      // 定义计算器工具
      let calculatorTool = Tool(
        name: "calculator",
        description: "执行基本数学计算",
        inputSchema: calculatorInputSchema
      )

      log("返回工具列表: weather, calculator", type: "RESPONSE")
      return ListTools.Result(tools: [weatherTool, calculatorTool])
    }

    // 处理工具调用请求
    await server.withMethodHandler(CallTool.self) { params in
      log("收到工具调用请求: \(params.name)", type: "REQUEST")
      log("工具参数: \(String(describing: params.arguments))", type: "REQUEST")

      // 根据工具名称处理不同的工具调用
      switch params.name {
      case "weather":
        return try await handleWeatherTool(params: params)
      case "calculator":
        return try await handleCalculatorTool(params: params)
      default:
        log("未知工具: \(params.name)", type: "ERROR")
        throw MCPServerError.toolError("未知工具: \(params.name)")
      }
    }
  }

  /// 处理天气工具调用
  /// - Parameter params: 工具调用参数
  /// - Returns: 工具调用响应
  private static func handleWeatherTool(params: CallTool.Parameters) async throws -> CallTool.Result {
    // 验证必要参数
    guard let arguments = params.arguments,
      let locationValue = arguments["location"],
      case .string(let location) = locationValue
    else {
      let message = "缺少必要参数: location"
      log(message, type: "ERROR")
      throw MCPServerError.toolError(message)
    }

    // 获取温度单位（使用默认值 celsius）
    var unit = "celsius"
    if let unitValue = params.arguments?["unit"], case .string(let unitString) = unitValue {
      unit = unitString
    }

    log("处理天气请求: 位置=\(location), 单位=\(unit)", type: "PROCESSING")

    // 模拟天气数据（在实际应用中，这里应当调用真实的天气 API）
    let temperature = unit == "celsius" ? 23 : 73.4

    // 构建响应内容
    let contentText = """
      位置: \(location)
      天气: 晴朗
      温度: \(temperature)°\(unit == "celsius" ? "C" : "F")
      湿度: 45%
      风向: 东北风 3级
      """

    log("天气查询成功: \(location)", type: "SUCCESS")

    // 返回响应
    return CallTool.Result(
      content: [.text(contentText)],
      isError: false
    )
  }

  /// 处理计算器工具调用
  /// - Parameter params: 工具调用参数
  /// - Returns: 工具调用响应
  private static func handleCalculatorTool(params: CallTool.Parameters) async throws -> CallTool.Result {
    // 验证必要参数
    guard let arguments = params.arguments,
      let expressionValue = arguments["expression"],
      case .string(let expression) = expressionValue
    else {
      let message = "缺少必要参数: expression"
      log(message, type: "ERROR")
      throw MCPServerError.toolError(message)
    }

    log("处理计算请求: \(expression)", type: "PROCESSING")

    // 在实际应用中，应当使用更安全的表达式解析库
    // 此处仅作为示例，使用简化的计算方法
    let result = try calculateExpression(expression)

    log("计算结果: \(expression) = \(result)", type: "SUCCESS")

    // 返回响应
    return CallTool.Result(
      content: [.text("计算结果: \(expression) = \(result)")],
      isError: false
    )
  }

  /// 简单的表达式计算函数（仅作示例使用）
  /// - Parameter expression: 要计算的表达式字符串
  /// - Returns: 计算结果
  private static func calculateExpression(_ expression: String) throws -> Double {
    // 注意：这是一个极其简化的计算器实现，仅用于演示
    // 实际应用中应使用适当的表达式解析库

    // 移除所有空格
    let cleanExpression = expression.replacingOccurrences(of: " ", with: "")

    // 尝试使用 NSExpression 计算结果
    let expr = NSExpression(format: cleanExpression)
    guard let result = expr.expressionValue(with: nil, context: nil) as? NSNumber else {
      throw MCPServerError.toolError("无法计算表达式: \(expression)")
    }

    return result.doubleValue
  }
}

// 主程序入口点
log("启动 MCP 服务器...", type: "STARTUP")

// 使用 Task 运行异步代码
Task {
  do {
    try await MCPServerApp.run()
  } catch {
    log("服务器运行错误: \(error.localizedDescription)", type: "ERROR")
    exit(1)
  }
}

// 保持主线程运行，直到程序结束
RunLoop.main.run()

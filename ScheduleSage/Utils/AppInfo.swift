//
//  AppInfo.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-26.
//

import Foundation

/// 提供应用程序基本信息的统一访问接口
public enum AppInfo {
    /// 返回本地化的应用显示名称
    /// - 返回值: 优先级：本地化显示名称 > Info.plist 显示名称 > Bundle 名称
    public static var displayName: String {
        Bundle.main.localizedInfoDictionary?["CFBundleDisplayName"] as? String
        ?? Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String
        ?? Bundle.main.infoDictionary?["CFBundleName"] as? String 
        ?? "ScheduleSage"
    }

    /// 返回应用 Bundle 名称
    public static var name: String {
        Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "ScheduleSage"
    }
    
    /// 返回应用版本号（例如：1.0.0）
    public static var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    /// 返回应用构建号
    public static var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    /// 返回完整版本信息（例如：1.0.0 (123)）
    public static var versionWithBuild: String {
        "\(version) (\(buildNumber))"
    }
    
    /// 返回应用包标识符
    public static var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "com.tiwenlab.schedulesage"
    }
    
    /// 返回应用支持的语言代码列表
    public static var supportedLanguages: [String] {
        Bundle.main.localizations
    }
    
    /// 返回当前应用使用的语言代码
    public static var currentLanguage: String {
        Bundle.main.preferredLocalizations.first ?? "en"
    }
    
    /// 返回应用是否在调试模式下运行
    public static var isDebug: Bool {
        #if DEBUG
            return true
        #else
            return false
        #endif
    }
    
    /// 返回应用基本信息字符串
    public static var appInformation: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let launchTime = dateFormatter.string(from: Date())
        
        return """
        App Information:
          Name: \(name)
          Version: \(version) (\(buildNumber))
          Bundle ID: \(bundleIdentifier)
          Launch Time: \(launchTime)
        """
    }
    
    /// 返回系统信息字符串
    public static var systemInformation: String {
        let processInfo = ProcessInfo.processInfo
        let memoryGB = Double(processInfo.physicalMemory) / 1024.0 / 1024.0 / 1024.0
        
        return """
        System Information:
          macOS Version: \(processInfo.operatingSystemVersionString)
          Physical Memory: \(String(format: "%.2f", memoryGB))GB
          Processor Count: \(processInfo.processorCount)
          Active Processor Count: \(processInfo.activeProcessorCount)
        """
    }
    
    /// 返回环境信息字符串
    public static var environmentInformation: String {
        let processInfo = ProcessInfo.processInfo
        
        return """
        Environment Information:
          Debug Mode: \(processInfo.environment["DEBUG"] != nil ? "Yes" : "No")
          Development: \(isDebug ? "Yes" : "No")
        """
    }
}
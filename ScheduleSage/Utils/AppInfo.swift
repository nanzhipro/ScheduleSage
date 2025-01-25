//
//  AppInfo.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-26.
//

import Foundation

/// AppInfo 负责管理应用程序的基本信息
/// 提供统一的接口来访问应用名称、版本号等信息
/// 支持本地化和非本地化的信息获取
public enum AppInfo {
    /// 获取应用显示名称
    /// 优先从本地化的 InfoPlist.strings 中获取 CFBundleDisplayName
    /// 如果未找到，则从 Info.plist 中获取 CFBundleDisplayName
    /// 如果仍未找到，则返回 Bundle 名称
    public static var displayName: String {
        // 1. 尝试从本地化的 InfoPlist.strings 获取
        if let localizedName = Bundle.main.localizedInfoDictionary?["CFBundleDisplayName"] as? String {
            return localizedName
        }
        
        // 2. 尝试从 Info.plist 获取
        if let name = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String {
            return name
        }
        
        // 3. 使用 Bundle 名称作为后备
        return Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "ScheduleSage"
    }
    
    /// 获取应用版本号
    public static var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    /// 获取应用构建版本号
    public static var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    /// 获取应用完整版本信息
    public static var versionWithBuild: String {
        "\(version) (\(buildNumber))"
    }
    
    /// 获取应用包标识符
    public static var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "com.tiwenlab.schedulesage"
    }
    
    /// 获取应用支持的语言列表
    public static var supportedLanguages: [String] {
        Bundle.main.localizations
    }
    
    /// 获取当前应用语言
    public static var currentLanguage: String {
        Bundle.main.preferredLocalizations.first ?? "en"
    }
} 
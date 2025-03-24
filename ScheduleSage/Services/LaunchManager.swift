//
//  LaunchManager.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-20.
//

import Foundation
import ServiceManagement

#if canImport(LaunchAtLogin)
import LaunchAtLogin
#endif

/// 管理应用程序的开机启动功能
public final class LaunchManager {
    public static let shared = LaunchManager()
    
    private let launchAgentIdentifier = "com.quest.schedulesage.launchagent"
    
    private init() {}
    
    /// 设置开机启动状态
    /// - Parameter enable: 是否启用开机启动
    /// - Returns: 操作是否成功
    @discardableResult
    public func setLaunchAtStartup(_ enable: Bool) -> Bool {
        #if canImport(LaunchAtLogin)
        // 使用LaunchAtLogin-Modern库
        LaunchAtLogin.isEnabled = enable
        return true
        #else
        // 回退到ServiceManagement方法
        do {
            if enable {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            return true
        } catch {
            print("Failed to \(enable ? "enable" : "disable") launch at startup: \(error)")
            return false
        }
        #endif
    }
    
    /// 检查是否已启用开机启动
    public var isLaunchAtStartupEnabled: Bool {
        #if canImport(LaunchAtLogin)
        // 使用LaunchAtLogin-Modern库
        return LaunchAtLogin.isEnabled
        #else
        // 回退到ServiceManagement方法
        return SMAppService.mainApp.status == .enabled
        #endif
    }
} 
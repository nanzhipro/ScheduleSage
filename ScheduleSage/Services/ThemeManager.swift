//
//  ThemeManager.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-20.
//

import SwiftUI
import AppKit

/// 管理应用程序的主题设置
public final class ThemeManager: ObservableObject {
    public static let shared = ThemeManager()
    
    private static let darkModeKey = "darkMode"
    
    @AppStorage(darkModeKey) private var isDarkMode: Bool = false
    @Published public private(set) var currentAppearance: NSAppearance
    
    private init() {
        // 从 UserDefaults 直接读取深色模式状态
        let isDarkMode = UserDefaults.standard.bool(forKey: Self.darkModeKey)
        
        // 初始化外观
        self.currentAppearance = NSAppearance(named: isDarkMode ? .darkAqua : .aqua) ?? .init(named: .aqua)!
        
        // 设置观察者监听系统外观变化
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handleAppearanceChange),
            name: Notification.Name("AppleInterfaceThemeChangedNotification"),
            object: nil
        )
        
        // 同时监听应用程序外观变化
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppearanceChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }
    
    /// 切换深色模式
    public func toggleDarkMode() {
        isDarkMode.toggle()
        updateAppearance()
    }
    
    /// 设置深色模式
    public func setDarkMode(_ enabled: Bool) {
        isDarkMode = enabled
        updateAppearance()
    }
    
    /// 是否启用深色模式
    public var isDarkModeEnabled: Bool {
        isDarkMode
    }
    
    /// 更新应用外观
    private func updateAppearance() {
        let newAppearance = NSAppearance(named: isDarkMode ? .darkAqua : .aqua) ?? .init(named: .aqua)!
        NSApplication.shared.appearance = newAppearance
        currentAppearance = newAppearance
        
        // 通知外观更改
        NotificationCenter.default.post(
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }
    
    /// 处理系统外观变化
    @objc private func handleAppearanceChange() {
        DispatchQueue.main.async {
            let appearance = NSApp.effectiveAppearance
            self.currentAppearance = appearance
            let newIsDarkMode = appearance.isDarkMode ?? false
            
            // 只在值发生变化时更新，避免不必要的通知
            if self.isDarkMode != newIsDarkMode {
                self.isDarkMode = newIsDarkMode
                
                // 发送主题变更通知
                NotificationCenter.default.post(name: .themeDidChange, object: nil)
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
} 
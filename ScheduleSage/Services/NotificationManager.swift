//
//  NotificationManager.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-20.
//

import Foundation
import UserNotifications
import AppKit

/// 管理应用程序的通知功能
public final class NotificationManager {
    public static let shared = NotificationManager()
    
    private init() {}
    
    /// 请求通知权限
    public func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if !granted {
                    self.openNotificationSettings()
                }
            }
        }
    }
    
    /// 检查通知权限状态
    public func checkNotificationStatus(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus == .authorized)
            }
        }
    }
    
    /// 打开系统通知设置
    public func openNotificationSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
            NSWorkspace.shared.open(url)
        }
    }
    
    /// 发送通知
    public func sendNotification(title: String, body: String, timeInterval: TimeInterval = 0) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let trigger = timeInterval > 0 
            ? UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
            : nil
            
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error sending notification: \(error)")
            }
        }
    }
    
    /// 清除所有待处理的通知
    public func clearAllPendingNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    /// 清除所有已显示的通知
    public func clearAllDeliveredNotifications() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
} 
//
//  NotificationManager.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-20.
//

import Foundation
import UserNotifications
import AppKit
import OSLog

/// 通知管理器
/// 管理应用程序的通知功能，包括权限管理、发送通知、处理通知交互等
/// Notification Manager
/// Manages application notifications, including permission management, sending notifications, and handling notification interactions
public final class NotificationManager: NSObject {
    // MARK: - Properties
    
    public static let shared = NotificationManager()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "ScheduleSage", category: "NotificationManager")
    private let notificationCenter = UNUserNotificationCenter.current()
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
        notificationCenter.delegate = self
        setupNotificationCategories()
    }
    
    // MARK: - Private Methods
    
    private func setupNotificationCategories() {
        // 定义日历事件通知的操作
        let viewAction = UNNotificationAction(
            identifier: "VIEW_EVENT",
            title: NSLocalizedString("view_event", comment: "View Event"),
            options: .foreground
        )
        
        let dismissAction = UNNotificationAction(
            identifier: "DISMISS",
            title: NSLocalizedString("dismiss", comment: "Dismiss"),
            options: .destructive
        )
        
        // 创建通知类别
        let calendarCategory = UNNotificationCategory(
            identifier: "calendar_event",
            actions: [viewAction, dismissAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        // 注册通知类别
        notificationCenter.setNotificationCategories([calendarCategory])
    }
    
    // MARK: - Public Methods
    
    /// 请求通知权限
    /// - Returns: 授权结果
    @discardableResult
    public func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            if !granted {
                await MainActor.run { self.openNotificationSettings() }
            }
            return granted
        } catch {
            logger.error("Failed to request notification authorization: \(error.localizedDescription)")
            return false
        }
    }
    
    /// 检查通知权限状态
    /// - Returns: 是否已授权
    public func checkNotificationStatus() async -> Bool {
        let settings = await notificationCenter.notificationSettings()
        return settings.authorizationStatus == .authorized
    }
    
    /// 发送通知
    /// - Parameters:
    ///   - title: 通知标题
    ///   - body: 通知内容
    ///   - delay: 延迟发送时间（可选）
    public func sendNotification(
        title: String,
        body: String,
        delay: TimeInterval = 0
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: delay > 0 ? UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false) : nil
        )
        
        Task {
            do {
                try await notificationCenter.add(request)
            } catch {
                logger.error("Failed to send notification: \(error.localizedDescription)")
            }
        }
    }
    
    /// 发送带有日历事件链接的通知
    /// - Parameters:
    ///   - title: 通知标题
    ///   - body: 通知内容
    ///   - eventId: 日历事件的唯一标识符
    ///   - delay: 延迟发送时间（可选）
    public func sendCalendarEventNotification(
        title: String,
        body: String,
        eventId: String,
        delay: TimeInterval = 0
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = ["eventId": eventId]
        content.categoryIdentifier = "calendar_event"  // 设置通知类别
        
        let request = UNNotificationRequest(
            identifier: "calendar-event-\(eventId)",
            content: content,
            trigger: delay > 0 ? UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false) : nil
        )
        
        Task {
            do {
                try await notificationCenter.add(request)
            } catch {
                logger.error("Failed to send calendar event notification: \(error.localizedDescription)")
            }
        }
    }
    
    /// 清除所有通知
    /// - Parameter type: 要清除的通知类型
    public func clearNotifications(_ type: NotificationType = .all) {
        switch type {
        case .pending:
            notificationCenter.removeAllPendingNotificationRequests()
        case .delivered:
            notificationCenter.removeAllDeliveredNotifications()
        case .all:
            notificationCenter.removeAllPendingNotificationRequests()
            notificationCenter.removeAllDeliveredNotifications()
        }
    }
}

// MARK: - Types

extension NotificationManager {
    /// 通知类型
    public enum NotificationType {
        case pending    // 待发送的通知
        case delivered  // 已发送的通知
        case all       // 所有通知
    }
}

// MARK: - Private Methods

private extension NotificationManager {
    func openNotificationSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") else { return }
        NSWorkspace.shared.open(url)
    }
    
    func openCalendarEvent(_ eventId: String) {
        guard let url = URL(string: "calshow://\(eventId)") else { return }
        NSWorkspace.shared.open(url)
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        switch response.actionIdentifier {
        case "VIEW_EVENT":
            if let eventId = response.notification.request.content.userInfo["eventId"] as? String {
                openCalendarEvent(eventId)
            }
        case UNNotificationDefaultActionIdentifier:
            // 用户点击通知本身
            if let eventId = response.notification.request.content.userInfo["eventId"] as? String {
                openCalendarEvent(eventId)
            }
        case UNNotificationDismissActionIdentifier:
            // 用户主动关闭通知
            break
        default:
            break
        }
        completionHandler()
    }
    
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}

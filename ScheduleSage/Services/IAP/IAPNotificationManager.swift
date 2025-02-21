//
//  IAPNotificationManager.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-14.
//

import Foundation
import UserNotifications

#if os(iOS)
import UIKit
#endif

/// IAP Notification Manager
/// 内购通知管理器
class IAPNotificationManager {
    static let shared = IAPNotificationManager()
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    private init() {
        setupNotifications()
    }
    
    private func setupNotifications() {
        #if os(iOS)
        // iOS 特定的通知设置
        UIApplication.shared.registerForRemoteNotifications()
        #endif
        
        notificationCenter.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Notification authorization error: \(error.localizedDescription)")
            }
        }
    }
    
    func scheduleExpirationReminder(for date: Date) {
        // 设置在过期前7天和1天发送提醒
        let reminders = [
            (days: 7, identifier: "subscription_expiry_7days"),
            (days: 1, identifier: "subscription_expiry_1day")
        ]
        
        for reminder in reminders {
            let reminderDate = date.addingTimeInterval(-Double(reminder.days * 24 * 60 * 60))
            if reminderDate > Date() {
                scheduleNotification(
                    identifier: reminder.identifier,
                    title: String(format: NSLocalizedString("subscription_expiry_reminder_title_%d", comment: ""), reminder.days),
                    body: String(format: NSLocalizedString("subscription_expiry_reminder_body_%d", comment: ""), reminder.days),
                    date: reminderDate
                )
            }
        }
    }
    
    func cancelAllExpirationReminders() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [
            "subscription_expiry_7days",
            "subscription_expiry_1day"
        ])
    }
    
    private func scheduleNotification(identifier: String, title: String, body: String, date: Date) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        #if os(iOS)
        content.categoryIdentifier = "subscription_reminder"
        #endif
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
} 
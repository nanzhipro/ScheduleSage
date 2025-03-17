//
//  CalendarFeedsViewModel.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-05-15.
//

import Foundation
import SwiftUI
import Combine
import EventKit

/// 日历事件流视图模型
/// 负责管理日历事件的获取和展示
class CalendarFeedsViewModel: ObservableObject {
    // MARK: - 发布属性
    @Published var events: [CalendarEventSummary] = []
    @Published var isLoading = true
    @Published var hasError = false
    @Published var errorMessage = ""
    
    // MARK: - 私有属性
    private let calendarManager = CalendarManager()
    private var cancellables = Set<AnyCancellable>()
    private let refreshInterval: TimeInterval = 300 // 5分钟刷新一次
    private var refreshTimer: Timer?
    private var calendarObserver: NSObjectProtocol?
    
    // MARK: - 初始化
    init() {
        setupRefreshTimer()
        setupCalendarObserver()
        loadTodayEvents()
    }
    
    deinit {
        refreshTimer?.invalidate()
        if let observer = calendarObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // MARK: - 公共方法
    
    /// 加载当日日历事件
    func loadTodayEvents() {
        isLoading = true
        hasError = false
        
        Task {
            do {
                // 获取所有当日事件
                let allEvents = try await calendarManager.fetchTodayEvents()
                
                let currentTime = Date()
                let futureEvents = allEvents.filter { event in
                    // 只保留非全天事件，且结束时间在当前时间之后的事件
                    !event.isAllDay && event.endDate > currentTime
                }
                
                // 按开始时间排序
                let sortedEvents = futureEvents.sorted { $0.startDate < $1.startDate }
                
                await MainActor.run {
                    self.events = sortedEvents
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.hasError = true
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    /// 手动刷新事件
    func refreshEvents() {
        loadTodayEvents()
    }
    
    // MARK: - 私有方法
    
    /// 设置定时刷新
    private func setupRefreshTimer() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            self?.loadTodayEvents()
        }
    }
    
    /// 设置日历变更观察者
    private func setupCalendarObserver() {
        // 监听日历数据库变更通知
        calendarObserver = NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            // 日历数据变更时刷新事件
            self?.loadTodayEvents()
        }
    }
} 

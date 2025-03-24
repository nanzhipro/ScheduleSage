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
    @Published var currentDate: Date = Date() // 当前选择的日期，默认为今天
    
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
        loadEventsForCurrentDate()
    }
    
    deinit {
        refreshTimer?.invalidate()
        if let observer = calendarObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // MARK: - 公共方法
    
    /// 加载当前选择日期的日历事件
    func loadEventsForCurrentDate() {
        isLoading = true
        hasError = false
        
        Task {
            do {
                // 获取所有当前选择日期的事件
                let allEvents = try await fetchEventsForDate(currentDate)
                
                let currentTime = Date()
                let futureEvents = allEvents.filter { event in
                    // 如果是今天，则只保留非全天事件，且结束时间在当前时间之后的事件
                    // 如果不是今天，则保留所有非全天事件
                    !event.isAllDay && (Calendar.current.isDateInToday(currentDate) ? event.endDate > currentTime : true)
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
    
    /// 切换到前一天
    func goToPreviousDay() {
        currentDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
        loadEventsForCurrentDate()
    }
    
    /// 切换到后一天
    func goToNextDay() {
        currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        loadEventsForCurrentDate()
    }
    
    /// 切换到今天
    func goToToday() {
        currentDate = Date()
        loadEventsForCurrentDate()
    }
    
    /// 获取格式化的当前日期字符串（例如：2024年5月15日 星期三）
    var formattedCurrentDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        return formatter.string(from: currentDate)
    }
    
    /// 获取当前选择日期的星期
    var weekdayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE" // 完整的星期名称
        return formatter.string(from: currentDate)
    }
    
    /// 手动刷新事件
    func refreshEvents() {
        loadEventsForCurrentDate()
    }
    
    /// 加载当日日历事件（向后兼容）
    func loadTodayEvents() {
        currentDate = Date()
        loadEventsForCurrentDate()
    }
    
    // MARK: - 私有方法
    
    /// 为指定日期获取事件
    private func fetchEventsForDate(_ date: Date) async throws -> [CalendarEventSummary] {
        try await calendarManager.fetchEventsForDate(date)
    }
    
    /// 设置定时刷新
    private func setupRefreshTimer() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if Calendar.current.isDateInToday(self.currentDate) {
                self.loadEventsForCurrentDate()
            }
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
            self?.loadEventsForCurrentDate()
        }
    }
} 

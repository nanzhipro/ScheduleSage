//
//  CalendarFeedsViewModel.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-05-15.
//

import Foundation
import SwiftUI
import Combine

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
    
    // MARK: - 初始化
    init() {
        setupRefreshTimer()
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
    
    // MARK: - 公共方法
    
    /// 加载当日日历事件
    func loadTodayEvents() {
        isLoading = true
        hasError = false
        
        Task {
            do {
                let todayEvents = try await calendarManager.fetchTodayEvents()
                await MainActor.run {
                    self.events = todayEvents
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
} 
//
//  MenuBarViewModel.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-06-12.
//

import Combine
import Foundation
import SwiftUI

/// 菜单栏视图模型
/// 负责管理状态栏中全天事件的获取和展示
class MenuBarViewModel: ObservableObject {
  // MARK: - 错误类型

  /// 视图模型错误类型
  enum EventLoadingError: Error, LocalizedError {
    case failedToLoadEvents(underlying: Error)

    var errorDescription: String? {
      switch self {
      case .failedToLoadEvents(let error):
        return error.localizedDescription
      }
    }
  }

  // MARK: - 发布属性

  /// 当天的全天事件列表
  @Published private(set) var allDayEvents: [CalendarEventSummary] = []

  /// 指示是否正在加载事件
  @Published private(set) var isLoading = false

  /// 指示是否发生错误
  @Published private(set) var hasError = false

  /// 发生错误时的错误信息
  @Published private(set) var errorMessage = ""

  /// 是否有可显示的事件
  var hasEvents: Bool { !allDayEvents.isEmpty }

  // MARK: - 私有属性
  private let calendarManager = CalendarManager()
  private var refreshTimer: Timer?
  private let refreshInterval: TimeInterval = 300  // 5分钟刷新一次

  // MARK: - 初始化

  /// 初始化视图模型
  /// 自动开始加载事件并设置定时刷新
  init() {
    refreshEvents()
    setupRefreshTimer()
  }

  deinit {
    refreshTimer?.invalidate()
  }

  // MARK: - 公共方法

  /// 刷新全天事件
  /// 触发异步加载当天的全天事件
  /// - 复杂度: 取决于CalendarManager.fetchTodayAllDayEvents实现
  func refreshEvents() {
    Task {
      await loadAllDayEvents()
    }
  }

  // MARK: - 私有方法

  /// 加载当日全天事件
  /// - 异步更新视图状态和事件列表
  /// - 发生错误时设置错误状态和消息
  @MainActor
  private func loadAllDayEvents() async {
    isLoading = true
    hasError = false

    do {
      allDayEvents = try await calendarManager.fetchTodayAllDayEvents()
    } catch {
      hasError = true
      errorMessage = error.localizedDescription
      allDayEvents = []
    }

    isLoading = false
  }

  /// 设置定时刷新
  /// 创建一个Timer来定期刷新事件列表
  /// - 注意: 使用弱引用防止循环引用
  private func setupRefreshTimer() {
    refreshTimer = Timer.scheduledTimer(
      withTimeInterval: refreshInterval,
      repeats: true
    ) { [weak self] _ in
      self?.refreshEvents()
    }
  }
}

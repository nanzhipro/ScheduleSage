//
//  CalendarFeedsView.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-05-15.
//

import SwiftUI
import EventKit

/// 日历事件流视图
/// 以若隐若现的方式展示当日日历事件
struct CalendarFeedsView: View {
    // MARK: - 属性
    @StateObject private var viewModel = CalendarFeedsViewModel()
    @Environment(\.colorScheme) private var colorScheme
    private let maxEventsToShow = 2 // 最多显示两条日程
    
    // MARK: - 初始化
    init() {}
    
    // MARK: - 视图主体
    var body: some View {
        VStack(spacing: 0) {
            // 内容
            if viewModel.isLoading {
                loadingStateView
            } else if viewModel.hasError {
                errorStateView
            } else if viewModel.events.isEmpty {
                emptyStateView
            } else {
                feedsContent
            }
        }
        .onAppear {
            viewModel.loadTodayEvents()
        }
        // 整体降低不透明度，减少存在感
        .opacity(colorScheme == .dark ? 0.5 : 0.6)
    }
    
    // MARK: - 事件流内容
    private var feedsContent: some View {
        VStack(spacing: 12) {
            ForEach(viewModel.events.prefix(maxEventsToShow)) { event in
                EventFeedItem(event: event)
            }
            
            // 如果有更多事件，显示"更多"提示
            if viewModel.events.count > maxEventsToShow {
                HStack {
                    Spacer()
                    Text(String(format: NSLocalizedString("more_events_count", comment: "还有 %d 个日程"), viewModel.events.count - maxEventsToShow))
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(colorScheme == .dark ? 
                            DesignSystem.Colors.secondaryText.opacity(0.6) : 
                            DesignSystem.Colors.secondaryText.opacity(0.6))
                    Spacer()
                }
                .padding(.top, 4)
            }
        }
    }
    
    // MARK: - 加载状态视图
    private var loadingStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "clock")
                .font(.system(size: 24))
                .foregroundColor(DesignSystem.Colors.secondaryText.opacity(0.4))
            
            Text(NSLocalizedString("loading_events", comment: "加载中..."))
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.secondaryText.opacity(0.4))
        }
        .padding()
        .opacity(0.6)
    }
    
    // MARK: - 空状态视图
    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 24))
                .foregroundColor(DesignSystem.Colors.secondaryText.opacity(0.4))
            
            Text(NSLocalizedString("no_events_today", comment: ""))
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.secondaryText.opacity(0.4))
        }
        .padding()
        .opacity(0.6)
    }
    
    // MARK: - 错误状态视图
    private var errorStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 24))
                .foregroundColor(DesignSystem.Colors.error.opacity(0.4))
            
            Text(NSLocalizedString("calendar_access_required", comment: ""))
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.secondaryText.opacity(0.4))
                .multilineTextAlignment(.center)
        }
        .padding()
        .opacity(0.6)
    }
}

// MARK: - 事件流项目
private struct EventFeedItem: View {
    // MARK: - 属性
    let event: CalendarEventSummary
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - 视图主体
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // 时间指示器
            timeIndicator
            
            // 事件内容
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.primaryText.opacity(colorScheme == .dark ? 0.7 : 0.75))
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    // 日历名称
                    Text(event.calendar)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText.opacity(colorScheme == .dark ? 0.5 : 0.6))
                    
                    // 时间范围
                    if !event.isAllDay {
                        Text(timeRangeText)
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.secondaryText.opacity(colorScheme == .dark ? 0.5 : 0.6))
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(backgroundGradient)
        )
        .contentShape(Rectangle())
    }
    
    // MARK: - 时间指示器
    private var timeIndicator: some View {
        ZStack {
            Circle()
                .fill(Color(nsColor: event.calendarColor.withAlphaComponent(colorScheme == .dark ? 0.1 : 0.1)))
                .frame(width: 40, height: 40)
            
            if event.isAllDay {
                Text(NSLocalizedString("all_day", comment: ""))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Color(nsColor: event.calendarColor).opacity(colorScheme == .dark ? 0.6 : 0.7))
            } else {
                Text(timeText)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(nsColor: event.calendarColor).opacity(colorScheme == .dark ? 0.6 : 0.7))
            }
        }
    }
    
    // MARK: - 背景渐变
    private var backgroundGradient: LinearGradient {
        if colorScheme == .dark {
            // 深色模式下的渐变 - 更加透明
            return LinearGradient(
                stops: [
                    .init(color: backgroundColor.opacity(0.02), location: 0),
                    .init(color: backgroundColor.opacity(0.08), location: 0.3),
                    .init(color: backgroundColor.opacity(0.08), location: 0.7),
                    .init(color: backgroundColor.opacity(0.02), location: 1)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        } else {
            // 浅色模式下的渐变 - 更加透明
            return LinearGradient(
                stops: [
                    .init(color: backgroundColor.opacity(0.005), location: 0),
                    .init(color: backgroundColor.opacity(0.03), location: 0.4),
                    .init(color: backgroundColor.opacity(0.03), location: 0.6),
                    .init(color: backgroundColor.opacity(0.005), location: 1)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
    
    // MARK: - 辅助计算属性
    private var backgroundColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    private var timeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: event.startDate)
    }
    
    private var timeRangeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return "\(formatter.string(from: event.startDate)) - \(formatter.string(from: event.endDate))"
    }
}

// MARK: - 预览
#Preview {
    CalendarFeedsView()
        .frame(width: 400, height: 300)
        .padding()
        .background(DesignSystem.Colors.background)
        .preferredColorScheme(.dark) // 添加暗黑模式预览
} 
//
//  MenuBarEventView.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-06-12.
//

import SwiftUI

/// 菜单栏事件视图，显示当日全天事件
struct MenuBarEventView: View {
  @StateObject private var viewModel = MenuBarViewModel()

  var body: some View {
    VStack(spacing: DesignSystem.Spacing.vertical) {
      // 头部
      headerView

      Divider()
        .background(DesignSystem.Colors.separator)

      // 内容区域
      contentView
    }
    .padding(DesignSystem.Layout.containerPadding)
    .frame(width: 300)
    .background {
      // 毛玻璃效果
      MenuBarVisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
        .cornerRadius(DesignSystem.Dimensions.cardCornerRadius)
        .edgesIgnoringSafeArea(.all)
    }
    .onAppear {
      viewModel.refreshEvents()
    }
  }

  // MARK: - 内容视图

  /// 根据视图模型状态显示适当的内容
  @ViewBuilder
  private var contentView: some View {
    if viewModel.isLoading {
      loadingView
    } else if viewModel.hasError {
      errorView
    } else if !viewModel.hasEvents {
      emptyStateView
    } else {
      eventsListView
    }
  }

  // MARK: - 子视图

  /// 头部视图，包含标题和刷新按钮
  private var headerView: some View {
    HStack {
      Text(NSLocalizedString("today_all_day_events", comment: "Today's Most Important Tasks"))
        .font(DesignSystem.Typography.headerTitle)
        .foregroundColor(DesignSystem.Colors.primaryText)

      Spacer()
    }
  }

  /// 加载中视图
  private var loadingView: some View {
    VStack(spacing: DesignSystem.Spacing.elementSpacing) {
      Spacer()
      ProgressView()
        .scaleEffect(1.2)
        .padding(.bottom, 8)
      Text(NSLocalizedString("loading_events", comment: "Loading events..."))
        .font(DesignSystem.Typography.caption)
        .foregroundColor(DesignSystem.Colors.secondaryText)
      Spacer()
    }
    .frame(maxWidth: .infinity, minHeight: 100)
  }

  /// 错误视图
  private var errorView: some View {
    VStack(spacing: DesignSystem.Spacing.textSpacing) {
      Spacer()
      Image(systemName: "exclamationmark.triangle")
        .font(.system(size: 28))
        .foregroundColor(DesignSystem.Colors.error)
        .padding(.bottom, 4)

      Text(NSLocalizedString("error_loading_events", comment: "Error loading tasks"))
        .font(DesignSystem.Typography.bodyMedium)
        .foregroundColor(DesignSystem.Colors.primaryText)

      Text(viewModel.errorMessage)
        .font(DesignSystem.Typography.caption)
        .foregroundColor(DesignSystem.Colors.secondaryText)
        .multilineTextAlignment(.center)
      Spacer()
    }
    .frame(maxWidth: .infinity, minHeight: 100)
    .padding()
  }

  /// 空状态视图 - 当没有全天事件时显示
  private var emptyStateView: some View {
    VStack(spacing: DesignSystem.Spacing.textSpacing) {
      Spacer()
      Image(systemName: "checklist")
        .font(.system(size: 32))
        .foregroundColor(DesignSystem.Colors.secondaryText)
        .padding(.bottom, 8)

      Text(NSLocalizedString("no_all_day_events", comment: "No important tasks today"))
        .font(DesignSystem.Typography.bodyMedium)
        .foregroundColor(DesignSystem.Colors.primaryText)
      Spacer()
    }
    .frame(maxWidth: .infinity, minHeight: 100)
    .padding()
  }

  /// 事件列表视图
  private var eventsListView: some View {
    ScrollView {
      VStack(spacing: DesignSystem.Spacing.elementSpacing) {
        ForEach(viewModel.allDayEvents) { event in
          AllDayEventRow(event: event)
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
      }
      .padding(.vertical, 4)
    }
    .frame(maxHeight: 300)
    .scrollIndicators(.hidden)
  }
}

/// 全天事件行组件
/// 显示单个全天事件的信息
struct AllDayEventRow: View {
  /// 要显示的事件
  let event: CalendarEventSummary
  @State private var isHovering = false

  var body: some View {
    HStack(spacing: DesignSystem.Spacing.iconSpacing) {
      // 日历颜色指示器
      calendarColorIndicator

      // 事件标题
      eventTitle

      Spacer()
    }
    .padding(12)
    .background(
      RoundedRectangle(cornerRadius: DesignSystem.Dimensions.cardCornerRadius)
        .fill(DesignSystem.Colors.cardBackground.opacity(isHovering ? 0.8 : 0.5))
    )
    .overlay(
      RoundedRectangle(cornerRadius: DesignSystem.Dimensions.cardCornerRadius)
        .stroke(Color(nsColor: event.calendarColor).opacity(0.4), lineWidth: 1)
    )
    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    // 点击打开事件
    .onTapGesture {
      openEvent()
    }
    .onHover { hovering in
      withAnimation(.easeInOut(duration: 0.2)) {
        isHovering = hovering
      }
    }
  }

  // MARK: - 私有视图组件

  /// 日历颜色指示器
  private var calendarColorIndicator: some View {
    Circle()
      .fill(Color(nsColor: event.calendarColor))
      .frame(width: 12, height: 12)
      .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
  }

  /// 事件标题
  private var eventTitle: some View {
    Text(event.title)
      .font(DesignSystem.Typography.bodyMedium)
      .foregroundColor(DesignSystem.Colors.primaryText)
      .lineLimit(1)
  }

  // MARK: - 私有方法

  /// 打开事件详情
  private func openEvent() {
    Task {
      await CalendarManager().openCalendarEvent(event.calendarItemIdentifier)
    }
  }
}

/// 圆形按钮样式
struct CircleButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .padding(6)
      .background(
        Circle()
          .fill(DesignSystem.Colors.cardBackground.opacity(configuration.isPressed ? 0.7 : 0.4))
      )
      .scaleEffect(configuration.isPressed ? 0.95 : 1)
      .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
  }
}

/// 毛玻璃效果包装器
struct MenuBarVisualEffectView: NSViewRepresentable {
  let material: NSVisualEffectView.Material
  let blendingMode: NSVisualEffectView.BlendingMode

  func makeNSView(context: Context) -> NSVisualEffectView {
    let view = NSVisualEffectView()
    view.material = material
    view.blendingMode = blendingMode
    view.state = .active
    return view
  }

  func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
    nsView.material = material
    nsView.blendingMode = blendingMode
  }
}

#Preview {
  MenuBarEventView()
}

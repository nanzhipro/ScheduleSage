//
//  MainNavigationView.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-20.
//

import SwiftUI

/// 主导航视图
/// 使用NavigationSplitView实现左右布局，包含日程添加和日历配置两个主要功能
struct MainNavigationView: View {
  // MARK: - Properties

  /// 环境对象
  @EnvironmentObject private var viewModel: AddScheduleViewModel
  @EnvironmentObject private var authViewModel: AuthenticationViewModel

  /// 当前选中的导航项
  @State private var selectedNavItem: NavigationItem?

  /// 导航项枚举
  enum NavigationItem: Hashable {
    case scheduleAdd
    case calendarSettings

    /// 导航项标题
    var title: String {
      switch self {
      case .scheduleAdd:
        return NSLocalizedString("schedule_add_title", comment: "Quick Add Event")
      case .calendarSettings:
        return NSLocalizedString("calendar_settings_title", comment: "Calendar Settings")
      }
    }

    /// 导航项图标
    var icon: String {
      switch self {
      case .scheduleAdd:
        return "calendar.badge.plus"
      case .calendarSettings:
        return "gear"
      }
    }
  }

  // MARK: - Body

  var body: some View {
    NavigationSplitView {
      // 侧边栏
      sidebarContent
        .navigationSplitViewColumnWidth(min: 200, ideal: 220)
    } detail: {
      // 详情视图
      detailContent
    }
  }

  // MARK: - 子视图

  /// 侧边栏内容
  private var sidebarContent: some View {
    List(selection: $selectedNavItem) {
      ForEach([NavigationItem.scheduleAdd, .calendarSettings], id: \.self) { item in
        NavigationLink(value: item) {
          Label {
            Text(item.title)
              .font(DesignSystem.Typography.bodyMedium)
          } icon: {
            Image(systemName: item.icon)
              .foregroundColor(DesignSystem.Colors.primary)
          }
        }
      }
    }
    .navigationTitle(NSLocalizedString("app_name", comment: "ScheduleSage"))
  }

  /// 详情视图内容
  @ViewBuilder
  private var detailContent: some View {
    if let selectedItem = selectedNavItem {
      switch selectedItem {
      case .scheduleAdd:
        AddScheduleView()
          .environmentObject(viewModel)
          .environmentObject(authViewModel)
      case .calendarSettings:
        CalendarSettingsView()
          .environmentObject(authViewModel)
      }
    } else {
      // 默认显示日程添加视图
      AddScheduleView()
        .environmentObject(viewModel)
        .environmentObject(authViewModel)
    }
  }
}

// MARK: - Preview
#Preview {
  MainNavigationView()
    .environmentObject(AddScheduleViewModel())
    .environmentObject(AuthenticationViewModel.shared)
}

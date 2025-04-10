//
//  CalendarSettingsView.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-20.
//

import SwiftUI

/// 日历配置视图
/// 用于管理日历相关的设置和配置
struct CalendarSettingsView: View {
  // MARK: - Properties
  @Environment(\.colorScheme) private var colorScheme

  // MARK: - Body
  var body: some View {
    VStack(spacing: DesignSystem.Spacing.vertical) {
      // 标题区域
      headerView

      // 内容区域
      contentView

      Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background {
      BackgroundView(colorScheme: colorScheme)
    }
  }

  // MARK: - 子视图

  /// 标题区域
  private var headerView: some View {
    VStack(spacing: DesignSystem.Spacing.textSpacing) {
      Text(NSLocalizedString("calendar_settings_title", comment: "Calendar Settings"))
        .font(DesignSystem.Typography.largeHeaderTitle)
        .foregroundColor(DesignSystem.Colors.primaryText)

      Text(NSLocalizedString("calendar_settings_subtitle", comment: "Manage your calendar preferences"))
        .font(DesignSystem.Typography.largeHeaderSubtitle)
        .foregroundColor(DesignSystem.Colors.secondaryText)
    }
    .padding(.top, DesignSystem.Spacing.vertical)
    .padding(.horizontal, DesignSystem.Spacing.horizontal)
  }

  /// 内容区域
  private var contentView: some View {
    VStack(spacing: DesignSystem.Spacing.sectionSpacing) {
      // 待实现的配置选项
      EmptyView()
    }
    .padding(DesignSystem.Layout.containerPadding)
  }
}

// MARK: - 背景视图
private struct BackgroundView: View {
  let colorScheme: ColorScheme

  var body: some View {
    DesignSystem.Gradients.containerBackground(colorScheme: colorScheme)
      .ignoresSafeArea()
  }
}

// MARK: - Preview
#Preview {
  CalendarSettingsView()
}

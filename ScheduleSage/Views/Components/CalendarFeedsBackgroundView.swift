//
//  CalendarFeedsBackgroundView.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-05-15.
//

import SwiftUI

/// 日历事件流背景视图
/// 以若隐若现的方式在背景中展示当日日历事件
struct CalendarFeedsBackgroundView: View {
  // MARK: - 属性
  @Environment(\.colorScheme) private var colorScheme

  // 控制整体透明度 - 进一步降低不透明度
  private var baseOpacity: Double {
    colorScheme == .dark ? 0.5 : 0.6  // 降低整体不透明度
  }

  // MARK: - 视图主体
  var body: some View {
    GeometryReader { geometry in
      // 使用 ZStack 和 center 对齐，确保内容居中
      ZStack(alignment: .center) {
        // 日历事件流容器 - 居中显示
        VStack {
          CalendarFeedsView()
            .frame(width: min(geometry.size.width * 0.8, 500))
            .padding(.horizontal, DesignSystem.Spacing.horizontal)
            .padding(.vertical, 16)
            // 减弱阴影效果
            .shadow(
              color: colorScheme == .dark ? DesignSystem.Colors.primary.opacity(0.08) : Color.black.opacity(0.03),
              radius: 10,
              x: 0,
              y: 3
            )
            // 几乎移除第二层阴影
            .shadow(
              color: colorScheme == .dark ? Color.black.opacity(0.1) : Color.black.opacity(0.02),
              radius: 2,
              x: 0,
              y: 1
            )
            .opacity(baseOpacity)
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .allowsHitTesting(true)  // 允许交互，以支持日期导航
    }
  }
}

// MARK: - 预览
#Preview {
  ZStack {
    Color.gray.opacity(0.2)

    CalendarFeedsBackgroundView()
  }
  .frame(width: 600, height: 400)
  .preferredColorScheme(.dark)  // 添加暗黑模式预览
}

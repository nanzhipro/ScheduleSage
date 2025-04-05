//
//  WindowBackgroundView.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-05-14.
//

import SwiftUI

/// 窗口背景视图
/// 提供Facebook Messenger风格的渐变背景效果
struct WindowBackgroundView: View {
  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    ZStack {
      // 夜晚模式使用深色渐变
      if colorScheme == .dark {
        // 基础背景颜色
        Color(red: 0.08, green: 0.08, blue: 0.12)
          .opacity(0.8)

        // 主要渐变效果 - 使用单层径向渐变
        RadialGradient(
          gradient: Gradient(colors: [
            Color(red: 0.2, green: 0.15, blue: 0.3).opacity(0.7),
            Color(red: 0.1, green: 0.1, blue: 0.2).opacity(0.5),
            Color(red: 0.07, green: 0.07, blue: 0.15).opacity(0.4),
          ]),
          center: .topLeading,
          startRadius: 100,
          endRadius: 600
        )
      }
      // 白天模式使用浅色渐变
      else {
        // 基础背景颜色
        Color(red: 0.95, green: 0.95, blue: 0.97)
          .opacity(0.8)

        // 主要渐变效果 - 使用单层径向渐变
        RadialGradient(
          gradient: Gradient(colors: [
            Color(red: 0.9, green: 0.92, blue: 0.97).opacity(0.7),
            Color(red: 0.85, green: 0.9, blue: 0.95).opacity(0.5),
            Color(red: 0.8, green: 0.85, blue: 0.9).opacity(0.4),
          ]),
          center: .topLeading,
          startRadius: 100,
          endRadius: 600
        )
      }
    }
    .ignoresSafeArea()
  }
}

#Preview {
  WindowBackgroundView()
}

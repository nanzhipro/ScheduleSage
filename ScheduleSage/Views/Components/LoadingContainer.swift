//
//  LoadingContainer.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-26.
//

import SwiftUI

/// LoadingContainer 负责显示加载状态的容器视图
/// 支持亮色和暗色模式
/// 提供加载遮罩和加载指示器
struct LoadingContainer<Content: View>: View {
  @StateObject private var loadingManager = LoadingManager.shared
  @Environment(\.colorScheme) private var colorScheme
  let content: Content

  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }

  var body: some View {
    ZStack {
      // 主要内容
      content

      // 加载遮罩和指示器
      if loadingManager.isLoading {
        Group {
          // 根据暗黑模式调整遮罩颜色和透明度
          if colorScheme == .dark {
            Color.white.opacity(0.1)
          } else {
            Color.black.opacity(0.2)
          }
        }
        .cornerRadius(DesignSystem.Dimensions.containerCornerRadius)
        .edgesIgnoringSafeArea(.all)

        LoadingIndicator(type: loadingManager.loadingType)
          .transition(.scale.combined(with: .opacity))
      }
    }
    .animation(.easeInOut(duration: 0.2), value: loadingManager.isLoading)
  }
}

// 视图扩展，使用更方便
extension View {
  func withLoading() -> some View {
    LoadingContainer { self }
  }
}

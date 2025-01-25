//
//  LoadingIndicator.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-26.
//

import SwiftUI

/// LoadingIndicator 负责显示加载动画和提示文本
/// 支持亮色和暗色模式
/// 提供加载动画和状态文本显示
struct LoadingIndicator: View {
  let type: LoadingType
  @State private var isAnimating = false
  @State private var scale: CGFloat = 0.8
  @State private var opacity: Double = 0
  @Environment(\.colorScheme) private var colorScheme

  private let animationDuration: Double = 1.0
  private let spinnerSize: CGFloat = 40
  private let strokeWidth: CGFloat = 4

  var body: some View {
    VStack(spacing: 16) {
      // 加载动画
      ZStack {
        // 背景圆环
        Circle()
          .stroke(
            colorScheme == .dark ? 
              DesignSystem.Colors.lightGray.opacity(0.3) : 
              DesignSystem.Colors.lightGray,
            lineWidth: strokeWidth
          )
          .frame(width: spinnerSize, height: spinnerSize)

        // 旋转的圆弧
        Circle()
          .trim(from: 0, to: 0.7)
          .stroke(
            colorScheme == .dark ?
              DesignSystem.Colors.primary.opacity(0.8) :
              DesignSystem.Colors.primary,
            lineWidth: strokeWidth
          )
          .frame(width: spinnerSize, height: spinnerSize)
          .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
      }

      // 加载文本
      Text(type.message)
        .font(DesignSystem.Typography.bodyRegular)
        .foregroundColor(
          colorScheme == .dark ?
            DesignSystem.Colors.secondaryText.opacity(0.9) :
            DesignSystem.Colors.secondaryText
        )
    }
    .padding()
    .background(
      RoundedRectangle(cornerRadius: DesignSystem.Dimensions.cardCornerRadius)
        .fill(colorScheme == .dark ? Color(.sRGB, white: 0.2, opacity: 0.95) : .white)
        .shadow(
          color: colorScheme == .dark ?
            Color.white.opacity(0.05) :
            Color.black.opacity(0.1),
          radius: colorScheme == .dark ? 15 : 10,
          x: 0,
          y: colorScheme == .dark ? 2 : 4
        )
    )
    .scaleEffect(scale)
    .opacity(opacity)
    .onAppear {
      withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
        scale = 1.0
        opacity = 1.0
      }

      withAnimation(
        Animation
          .linear(duration: animationDuration)
          .repeatForever(autoreverses: false)
      ) {
        isAnimating = true
      }
    }
    .onDisappear {
      withAnimation(.easeOut(duration: 0.2)) {
        scale = 0.8
        opacity = 0
      }
    }
  }
}

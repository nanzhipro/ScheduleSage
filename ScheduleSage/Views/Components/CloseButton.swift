//
//  SageCloseButton.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-20.
//

import SwiftUI

/// 关闭按钮组件
/// 提供清晰的视觉反馈和足够大的触控区域
struct SageCloseButton: View {
  let action: () -> Void
  @State private var isHovering = false
  
  var body: some View {
    Button(action: action) {
      ZStack {
        // 背景圆形
        Circle()
          .fill(
            isHovering
              ? DesignSystem.Colors.hoverBackground
              : DesignSystem.Colors.hoverBackground.opacity(0.001)
          )
          .frame(width: 36, height: 36)
        
        // 关闭图标
        Image(systemName: "xmark")
          .font(.system(size: 13, weight: .medium))
          .foregroundColor(
            isHovering
              ? DesignSystem.Colors.primaryText
              : DesignSystem.Colors.secondaryGray
          )
          .frame(width: 28, height: 28)
      }
    }
    .buttonStyle(.plain)
    .onHover { hovering in
      withAnimation(.easeInOut(duration: 0.2)) {
        isHovering = hovering
      }
    }
    .contentShape(Circle()) // 确保整个圆形区域都可点击
  }
}

#if DEBUG
struct SageCloseButton_Previews: PreviewProvider {
  static var previews: some View {
    SageCloseButton(action: {})
      .padding()
      .previewLayout(.sizeThatFits)
  }
}
#endif 
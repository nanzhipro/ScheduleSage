//
//  SSTitleSection.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-05-15.
//

import SwiftUI

/// 标题区域组件
/// 提供一个包含主标题和副标题的区域，支持悬停效果
struct SSTitleSection: View {
  // 主标题
  let title: String
  // 副标题
  let subtitle: String
  // 标题样式
  let style: Style
  // 是否启用悬停效果
  let enableHoverEffect: Bool
  
  @State private var isHovered = false
  @Environment(\.colorScheme) private var colorScheme
  
  /// 初始化标题区域
  /// - Parameters:
  ///   - title: 主标题
  ///   - subtitle: 副标题
  ///   - style: 标题样式，默认为.standard
  ///   - enableHoverEffect: 是否启用悬停效果，默认为true
  init(
    title: String,
    subtitle: String,
    style: Style = .standard,
    enableHoverEffect: Bool = true
  ) {
    self.title = title
    self.subtitle = subtitle
    self.style = style
    self.enableHoverEffect = enableHoverEffect
  }
  
  var body: some View {
    VStack(spacing: style.spacing) {
      // 主标题
      Text(title)
        .font(style.titleFont)
        .foregroundStyle(
          LinearGradient(
            colors: [
              DesignSystem.Colors.primary,
              DesignSystem.Colors.primary.opacity(0.8)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
        .shadow(
          color: colorScheme == .dark ? 
            DesignSystem.Colors.primary.opacity(0.3) : 
            .clear,
          radius: isHovered && enableHoverEffect ? 15 : 10
        )
        .scaleEffect(isHovered && enableHoverEffect ? 1.05 : 1.0)
      
      // 副标题
      Text(subtitle)
        .font(style.subtitleFont)
        .foregroundColor(style.subtitleColor)
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .opacity(isHovered && enableHoverEffect ? 0.9 : 0.8)
    }
    .padding(.horizontal)
    .contentShape(Rectangle())
    .onHover { hovering in
      guard enableHoverEffect else { return }
      withAnimation(.easeInOut(duration: 0.2)) {
        isHovered = hovering
      }
    }
  }
  
  /// 标题样式配置
  struct Style {
    let titleFont: Font
    let subtitleFont: Font
    let subtitleColor: Color
    let spacing: CGFloat
    
    /// 小型样式
    static let small = Style(
      titleFont: .system(size: 24, weight: .bold, design: .rounded),
      subtitleFont: .system(size: 14, weight: .medium, design: .rounded),
      subtitleColor: .black,
      spacing: 8
    )
    
    /// 标准样式
    static let standard = Style(
      titleFont: .system(size: 36, weight: .bold, design: .rounded),
      subtitleFont: .system(size: 16, weight: .medium, design: .rounded),
      subtitleColor: .black,
      spacing: 12
    )
    
    /// 大型样式
    static let large = Style(
      titleFont: .system(size: 48, weight: .bold, design: .rounded),
      subtitleFont: .system(size: 18, weight: .medium, design: .rounded),
      subtitleColor: .black,
      spacing: 16
    )
  }
}

#if DEBUG
struct SSTitleSection_Previews: PreviewProvider {
  static var previews: some View {
    VStack(spacing: 40) {
      SSTitleSection(
        title: "Schedule Sage",
        subtitle: "智能日程管理助手",
        style: .small
      )
      .previewDisplayName("Small")
      
      SSTitleSection(
        title: "Schedule Sage",
        subtitle: "智能日程管理助手"
      )
      .previewDisplayName("Standard")
      
      SSTitleSection(
        title: "Schedule Sage",
        subtitle: "智能日程管理助手",
        style: .large
      )
      .previewDisplayName("Large")
    }
    .padding()
    .previewLayout(.sizeThatFits)
  }
}
#endif 
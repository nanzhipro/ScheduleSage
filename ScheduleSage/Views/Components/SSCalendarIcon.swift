//
//  SSCalendarIcon.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-05-15.
//

import SwiftUI

/// 日历图标组件
/// 提供一个可配置的日历图标，支持动画效果和高级会员标识
struct SSCalendarIcon: View {
  // 动画类型
  let animation: AnimationType
  // 图标名称
  let iconName: String
  // 图标尺寸
  let size: IconSize
  // 是否显示高级会员标识
  let showPremiumBadge: Bool
  
  /// 初始化日历图标
  /// - Parameters:
  ///   - animation: 动画类型，默认为.none
  ///   - iconName: 图标名称，默认为"calendar.badge.plus"
  ///   - size: 图标尺寸，默认为.medium
  ///   - showPremiumBadge: 是否显示高级会员标识，默认为false
  init(
    animation: AnimationType = .none,
    iconName: String = "calendar.badge.plus",
    size: IconSize = .medium,
    showPremiumBadge: Bool = false
  ) {
    self.animation = animation
    self.iconName = iconName
    self.size = size
    self.showPremiumBadge = showPremiumBadge
  }
  
  var body: some View {
    ZStack {
      // 基础日历图标
      ZStack {
        Circle()
          .fill(DesignSystem.Colors.secondaryBackground)
          .frame(width: size.containerSize, height: size.containerSize)
        
        Image(systemName: iconName)
          .font(.system(size: size.iconSize))
          .foregroundColor(DesignSystem.Colors.primary)
      }
      .modifier(AnimationModifier(animation: animation))
      
      // 高级会员标识
      if showPremiumBadge {
        Image(systemName: "crown.fill")
          .font(.system(size: size.badgeSize))
          .foregroundColor(.yellow)
          .shadow(color: .yellow.opacity(0.3), radius: 4)
          .offset(y: -size.containerSize/2 - size.badgeOffset)
          .transition(.scale.combined(with: .opacity))
      }
    }
  }
  
  /// 图标尺寸配置
  struct IconSize {
    let containerSize: CGFloat
    let iconSize: CGFloat
    let badgeSize: CGFloat
    let badgeOffset: CGFloat
    
    /// 小尺寸
    static let small = IconSize(
      containerSize: 60,
      iconSize: 30,
      badgeSize: 16,
      badgeOffset: 6
    )
    
    /// 中等尺寸
    static let medium = IconSize(
      containerSize: 100,
      iconSize: 48,
      badgeSize: 24,
      badgeOffset: 10
    )
    
    /// 大尺寸
    static let large = IconSize(
      containerSize: 140,
      iconSize: 64,
      badgeSize: 32,
      badgeOffset: 14
    )
  }
  
  /// 动画类型
  enum AnimationType {
    case none
    case pulse
    case scale
    case bounce
    case glow
  }
  
  /// 动画修饰器
  struct AnimationModifier: ViewModifier {
    let animation: AnimationType
    
    func body(content: Content) -> some View {
      content
        .scaleEffect(animation == .pulse ? 1.1 : (animation == .scale ? 1.2 : 1.0))
        .offset(y: animation == .bounce ? -10 : 0)
        .shadow(
          color: animation == .glow ? DesignSystem.Colors.primary.opacity(0.5) : .clear,
          radius: animation == .glow ? 20 : 0
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: animation)
    }
  }
}

#if DEBUG
struct SSCalendarIcon_Previews: PreviewProvider {
  static var previews: some View {
    VStack(spacing: 40) {
      HStack(spacing: 20) {
        SSCalendarIcon(size: .small)
          .previewDisplayName("Small")
        
        SSCalendarIcon()
          .previewDisplayName("Medium")
        
        SSCalendarIcon(size: .large)
          .previewDisplayName("Large")
      }
      
      HStack(spacing: 20) {
        SSCalendarIcon(animation: .pulse)
          .previewDisplayName("Pulse")
        
        SSCalendarIcon(animation: .scale)
          .previewDisplayName("Scale")
        
        SSCalendarIcon(animation: .bounce)
          .previewDisplayName("Bounce")
      }
      
      HStack(spacing: 20) {
        SSCalendarIcon(showPremiumBadge: true)
          .previewDisplayName("With Premium Badge")
        
        SSCalendarIcon(
          animation: .glow,
          iconName: "calendar.badge.clock",
          showPremiumBadge: true
        )
        .previewDisplayName("Custom")
      }
    }
    .padding()
    .previewLayout(.sizeThatFits)
  }
}
#endif 
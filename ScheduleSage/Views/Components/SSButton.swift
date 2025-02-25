//
//  SSButton.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-05-15.
//

import SwiftUI

/// 通用按钮组件
/// 提供一个可配置的按钮，支持多种样式和交互效果
struct SSButton: View {
  // 按钮点击事件
  let action: () -> Void
  // 按钮标题
  let title: String
  // 按钮图标名称（可选）
  let iconName: String?
  // 按钮样式
  let style: Style
  // 是否禁用
  let isDisabled: Bool
  
  @State private var isHovered = false
  @State private var isPressed = false
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.ssPremiumButtonIconColor) private var customIconColor
  
  /// 初始化按钮
  /// - Parameters:
  ///   - title: 按钮标题
  ///   - iconName: 按钮图标名称（可选）
  ///   - style: 按钮样式，默认为.primary
  ///   - isDisabled: 是否禁用，默认为false
  ///   - action: 按钮点击事件
  init(
    _ title: String,
    iconName: String? = nil,
    style: Style = .primary,
    isDisabled: Bool = false,
    action: @escaping () -> Void
  ) {
    self.title = title
    self.iconName = iconName
    self.style = style
    self.isDisabled = isDisabled
    self.action = action
  }
  
  var body: some View {
    Button(action: handleButtonTap) {
      HStack(spacing: 8) {
        // 如果有图标则显示
        if let iconName = iconName {
          Image(systemName: iconName)
            .font(style.iconFont)
            .foregroundColor(iconColor)
        }
        
        Text(NSLocalizedString(title, comment: ""))
          .font(style.textFont)
          .foregroundColor(foregroundColor)
      }
      .frame(maxWidth: style.isFullWidth ? .infinity : nil)
      .frame(height: style.height)
      .padding(.horizontal, style.horizontalPadding)
      .background(
        RoundedRectangle(cornerRadius: style.cornerRadius)
          .fill(backgroundColor)
      )
      .overlay(
        RoundedRectangle(cornerRadius: style.cornerRadius)
          .strokeBorder(style.borderColor(isHovered: isHovered, isDisabled: isDisabled, colorScheme: colorScheme), lineWidth: style.borderWidth)
          .opacity(style.hasBorder ? 1 : 0)
      )
      .scaleEffect(isPressed ? 0.98 : 1.0)
      .opacity(isDisabled ? 0.6 : 1.0)
    }
    .buttonStyle(.plain)
    .onHover { hovering in
      guard !isDisabled else { return }
      withAnimation(.easeInOut(duration: 0.2)) {
        isHovered = hovering
      }
    }
    .disabled(isDisabled)
  }
  
  /// 处理按钮点击事件
  private func handleButtonTap() {
    guard !isDisabled else { return }
    
    withAnimation(.easeOut(duration: 0.1)) {
      isPressed = true
    }
    
    // 触觉反馈
    NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .default)
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      withAnimation(.easeOut(duration: 0.1)) {
        isPressed = false
      }
      action()
    }
  }
  
  /// 获取图标颜色
  private var iconColor: Color {
    if let customColor = customIconColor {
      return customColor
    }
    return foregroundColor
  }
  
  /// 获取前景色
  private var foregroundColor: Color {
    style.foregroundColor(
      isHovered: isHovered,
      isPressed: isPressed,
      isDisabled: isDisabled,
      colorScheme: colorScheme
    )
  }
  
  /// 获取背景色
  private var backgroundColor: Color {
    style.backgroundColor(
      isHovered: isHovered,
      isPressed: isPressed,
      isDisabled: isDisabled,
      colorScheme: colorScheme
    )
  }
  
  /// 按钮样式
  struct Style {
    // 文本字体
    let textFont: Font
    // 图标字体
    let iconFont: Font
    // 按钮高度
    let height: CGFloat
    // 水平内边距
    let horizontalPadding: CGFloat
    // 圆角半径
    let cornerRadius: CGFloat
    // 是否占满宽度
    let isFullWidth: Bool
    // 是否有边框
    let hasBorder: Bool
    // 边框宽度
    let borderWidth: CGFloat
    // 样式类型
    let type: StyleType
    
    /// 样式类型
    enum StyleType {
      case primary
      case secondary
      case tertiary
      case destructive
      case ghost
      case link
    }
    
    /// 获取前景色
    func foregroundColor(isHovered: Bool, isPressed: Bool, isDisabled: Bool, colorScheme: ColorScheme) -> Color {
      if isDisabled {
        return disabledForegroundColor(colorScheme: colorScheme)
      }
      
      switch type {
      case .primary:
        return DesignSystem.Colors.background
      case .secondary, .tertiary:
        return DesignSystem.Colors.primary
      case .destructive:
        return .white
      case .ghost, .link:
        return DesignSystem.Colors.primary
      }
    }
    
    /// 获取背景色
    func backgroundColor(isHovered: Bool, isPressed: Bool, isDisabled: Bool, colorScheme: ColorScheme) -> Color {
      if isDisabled {
        return disabledBackgroundColor(colorScheme: colorScheme)
      }
      
      switch type {
      case .primary:
        if isPressed {
          return DesignSystem.Colors.primary.opacity(0.8)
        } else if isHovered {
          return DesignSystem.Colors.primary.opacity(0.9)
        }
        return DesignSystem.Colors.primary
        
      case .secondary:
        if isPressed {
          return DesignSystem.Colors.primary.opacity(0.2)
        } else if isHovered {
          return DesignSystem.Colors.primary.opacity(0.1)
        }
        return DesignSystem.Colors.primary.opacity(0.05)
        
      case .tertiary:
        return .clear
        
      case .destructive:
        if isPressed {
          return Color.red.opacity(0.8)
        } else if isHovered {
          return Color.red.opacity(0.9)
        }
        return .red
        
      case .ghost:
        if isPressed {
          return DesignSystem.Colors.primary.opacity(0.1)
        } else if isHovered {
          return DesignSystem.Colors.primary.opacity(0.05)
        }
        return .clear
        
      case .link:
        return .clear
      }
    }
    
    /// 获取边框颜色
    func borderColor(isHovered: Bool, isDisabled: Bool, colorScheme: ColorScheme) -> Color {
      if isDisabled {
        return DesignSystem.Colors.secondaryText.opacity(0.3)
      }
      
      switch type {
      case .tertiary:
        return DesignSystem.Colors.primary.opacity(isHovered ? 0.8 : 0.5)
      case .ghost:
        return DesignSystem.Colors.primary.opacity(isHovered ? 0.3 : 0.2)
      default:
        return .clear
      }
    }
    
    /// 获取禁用状态前景色
    private func disabledForegroundColor(colorScheme: ColorScheme) -> Color {
      switch type {
      case .primary:
        return DesignSystem.Colors.background.opacity(0.8)
      default:
        return DesignSystem.Colors.secondaryText
      }
    }
    
    /// 获取禁用状态背景色
    private func disabledBackgroundColor(colorScheme: ColorScheme) -> Color {
      switch type {
      case .primary:
        return DesignSystem.Colors.secondaryText
      case .secondary:
        return DesignSystem.Colors.secondaryBackground
      case .tertiary, .ghost, .link:
        return .clear
      case .destructive:
        return Color.red.opacity(0.3)
      }
    }
    
    // MARK: - 预定义样式
    
    /// 主要按钮样式
    static let primary = Style(
      textFont: DesignSystem.Typography.buttonLabel,
      iconFont: .system(size: 16),
      height: DesignSystem.Dimensions.buttonHeight,
      horizontalPadding: 16,
      cornerRadius: DesignSystem.Dimensions.buttonCornerRadius,
      isFullWidth: true,
      hasBorder: false,
      borderWidth: 0,
      type: .primary
    )
    
    /// 次要按钮样式
    static let secondary = Style(
      textFont: DesignSystem.Typography.buttonLabel,
      iconFont: .system(size: 16),
      height: DesignSystem.Dimensions.buttonHeight,
      horizontalPadding: 16,
      cornerRadius: DesignSystem.Dimensions.buttonCornerRadius,
      isFullWidth: true,
      hasBorder: false,
      borderWidth: 0,
      type: .secondary
    )
    
    /// 第三级按钮样式（带边框）
    static let tertiary = Style(
      textFont: DesignSystem.Typography.buttonLabel,
      iconFont: .system(size: 16),
      height: DesignSystem.Dimensions.buttonHeight,
      horizontalPadding: 16,
      cornerRadius: DesignSystem.Dimensions.buttonCornerRadius,
      isFullWidth: true,
      hasBorder: true,
      borderWidth: 1,
      type: .tertiary
    )
    
    /// 破坏性操作按钮样式
    static let destructive = Style(
      textFont: DesignSystem.Typography.buttonLabel,
      iconFont: .system(size: 16),
      height: DesignSystem.Dimensions.buttonHeight,
      horizontalPadding: 16,
      cornerRadius: DesignSystem.Dimensions.buttonCornerRadius,
      isFullWidth: true,
      hasBorder: false,
      borderWidth: 0,
      type: .destructive
    )
    
    /// 幽灵按钮样式
    static let ghost = Style(
      textFont: DesignSystem.Typography.buttonLabel,
      iconFont: .system(size: 16),
      height: DesignSystem.Dimensions.buttonHeight,
      horizontalPadding: 16,
      cornerRadius: DesignSystem.Dimensions.buttonCornerRadius,
      isFullWidth: false,
      hasBorder: true,
      borderWidth: 1,
      type: .ghost
    )
    
    /// 链接按钮样式
    static let link = Style(
      textFont: DesignSystem.Typography.bodyMedium,
      iconFont: .system(size: 14),
      height: 32,
      horizontalPadding: 8,
      cornerRadius: 4,
      isFullWidth: false,
      hasBorder: false,
      borderWidth: 0,
      type: .link
    )
    
    /// 小型按钮样式
    static let small = Style(
      textFont: DesignSystem.Typography.caption,
      iconFont: .system(size: 12),
      height: 32,
      horizontalPadding: 12,
      cornerRadius: 6,
      isFullWidth: false,
      hasBorder: false,
      borderWidth: 0,
      type: .primary
    )
    
    /// 大型按钮样式
    static let large = Style(
      textFont: DesignSystem.Typography.title,
      iconFont: .system(size: 20),
      height: DesignSystem.Dimensions.largeButtonHeight,
      horizontalPadding: 24,
      cornerRadius: 10,
      isFullWidth: true,
      hasBorder: false,
      borderWidth: 0,
      type: .primary
    )
  }
}

// MARK: - 预览
#if DEBUG
struct SSButton_Previews: PreviewProvider {
  static var previews: some View {
    VStack(spacing: 20) {
      Group {
        SSButton("Primary Button", style: .primary) {}
        SSButton("Secondary Button", style: .secondary) {}
        SSButton("Tertiary Button", style: .tertiary) {}
        SSButton("Destructive Button", style: .destructive) {}
        SSButton("Ghost Button", style: .ghost) {}
      }
      .previewLayout(.sizeThatFits)
      
      Group {
        SSButton("With Icon", iconName: "star.fill", style: .primary) {}
        SSButton("Disabled Button", style: .primary, isDisabled: true) {}
        SSButton("Small Button", style: .small) {}
        SSButton("Large Button", style: .large) {}
        SSButton("Link Button", iconName: "link", style: .link) {}
      }
      .previewLayout(.sizeThatFits)
    }
    .padding()
  }
}
#endif 
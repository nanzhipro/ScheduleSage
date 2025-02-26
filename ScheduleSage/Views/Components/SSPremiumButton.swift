//
//  SSPremiumButton.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-05-15.
//

import SwiftUI

/// 高级会员按钮组件
/// 提供一个可点击的升级到高级会员的按钮
struct SSPremiumButton: View {
  // 按钮点击事件
  let action: () -> Void
  // 按钮文本
  let title: String
  // 按钮图标
  let iconName: String
  // 按钮样式配置
  let style: Style
  // 是否显示按钮
  let shouldShow: Bool
  
  /// 初始化高级会员按钮
  /// - Parameters:
  ///   - action: 按钮点击事件
  ///   - title: 按钮文本，默认为"升级到高级会员"
  ///   - iconName: 按钮图标，默认为"star.fill"
  ///   - style: 按钮样式配置，默认为.compact
  ///   - shouldShow: 是否显示按钮，默认为 true
  init(
    action: @escaping () -> Void,
    title: String? = nil,
    iconName: String = "star.fill",
    style: Style = .compact,
    shouldShow: Bool = true
  ) {
    self.action = action
    self.title = title ?? NSLocalizedString("upgrade_to_premium", comment: "")
    self.iconName = iconName
    self.style = style
    self.shouldShow = shouldShow
  }
  
  var body: some View {
    if shouldShow {
      SSButton(
        title,
        iconName: iconName,
        style: style.toSSButtonStyle(),
        action: action
      )
      .foregroundColor(.yellow, for: .icon)
    }
  }
  
  /// 按钮样式配置
  struct Style {
    let iconFont: Font
    let textFont: Font
    let spacing: CGFloat
    let verticalPadding: CGFloat
    let horizontalPadding: CGFloat
    let cornerRadius: CGFloat
    
    /// 转换为SSButton样式
    func toSSButtonStyle() -> SSButton.Style {
      SSButton.Style(
        textFont: textFont,
        iconFont: iconFont,
        height: verticalPadding * 2 + 24, // 估算高度
        horizontalPadding: horizontalPadding,
        cornerRadius: cornerRadius,
        isFullWidth: false,
        hasBorder: false,
        borderWidth: 0,
        type: .ghost
      )
    }
    
    /// 紧凑型样式
    static let compact = Style(
      iconFont: .system(size: 12),
      textFont: DesignSystem.Typography.caption,
      spacing: 4,
      verticalPadding: 6,
      horizontalPadding: 12,
      cornerRadius: 6
    )
    
    /// 标准样式
    static let standard = Style(
      iconFont: .system(size: 16),
      textFont: DesignSystem.Typography.bodyMedium,
      spacing: 8,
      verticalPadding: 10,
      horizontalPadding: 16,
      cornerRadius: 8
    )
    
    /// 大型样式
    static let large = Style(
      iconFont: .system(size: 20),
      textFont: DesignSystem.Typography.title,
      spacing: 12,
      verticalPadding: 14,
      horizontalPadding: 24,
      cornerRadius: 10
    )
  }
}

// MARK: - 扩展SSButton以支持特定元素的前景色
extension SSButton {
  enum ElementType {
    case icon
    case text
  }
  
  func foregroundColor(_ color: Color, for element: ElementType) -> some View {
    self.environment(\.ssPremiumButtonIconColor, element == .icon ? color : nil)
  }
}

// MARK: - 环境键
private struct SSPremiumButtonIconColorKey: EnvironmentKey {
  static let defaultValue: Color? = nil
}

extension EnvironmentValues {
  var ssPremiumButtonIconColor: Color? {
    get { self[SSPremiumButtonIconColorKey.self] }
    set { self[SSPremiumButtonIconColorKey.self] = newValue }
  }
}

#if DEBUG
struct SSPremiumButton_Previews: PreviewProvider {
  static var previews: some View {
    VStack(spacing: 20) {
      SSPremiumButton(action: {})
        .previewDisplayName("Compact")
      
      SSPremiumButton(action: {}, style: .standard)
        .previewDisplayName("Standard")
      
      SSPremiumButton(action: {}, style: .large)
        .previewDisplayName("Large")
    }
    .padding()
    .previewLayout(.sizeThatFits)
  }
}
#endif 
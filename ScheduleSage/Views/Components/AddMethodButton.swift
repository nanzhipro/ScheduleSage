//
//  AddMethodButton.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024/03/26.
//

import SwiftUI

/// 添加方法按钮组件
/// 提供一个可点击的方法选择按钮，包含图标和文本
/// 支持悬停和点击动画效果
struct AddMethodButton: View {
  /// 按钮的系统图标名称
  let iconName: String
  
  /// 按钮的显示文本
  let title: String
  
  /// 按钮的提示文本键
  let hintKey: String
  
  /// 按钮点击时的回调操作
  let action: (() -> Void)?
  
  /// 按钮是否处于悬停状态
  @State private var isHovered = false
  
  /// 按钮是否处于按下状态
  @State private var isPressed = false
  
  /// 当前系统的颜色方案
  @Environment(\.colorScheme) private var colorScheme
  
  /// 创建一个添加方法按钮
  /// - Parameters:
  ///   - iconName: 按钮使用的 SF Symbols 图标名称
  ///   - title: 按钮显示的文本
  ///   - hintKey: 按钮提示文本的本地化键
  ///   - action: 可选的点击回调操作
  init(
    iconName: String,
    title: String,
    hintKey: String,
    action: (() -> Void)? = nil
  ) {
    self.iconName = iconName
    self.title = title
    self.hintKey = hintKey
    self.action = action
  }
  
  /// 背景颜色，根据悬停和按下状态动态变化
  private var backgroundColor: Color {
    if isPressed {
      return DesignSystem.Colors.primary.opacity(0.1)
    } else if isHovered {
      return DesignSystem.Colors.primary.opacity(0.05)
    }
    return .clear
  }
  
  /// 图标的颜色，使用主题色但带有透明度
  private var iconColor: Color {
    if isHovered {
      return DesignSystem.Colors.primary.opacity(0.8)
    }
    return DesignSystem.Colors.primary.opacity(0.8)
  }
  
  /// 文本的颜色，使用标题文本颜色
  private var titleColor: Color {
    if isHovered {
      return DesignSystem.Colors.primaryText
    }
    return DesignSystem.Colors.primaryText
  }
  
  var body: some View {
    Button(action: handleButtonTap) {
      VStack(spacing: 8) {
        makeIconView()
        makeTitleView()
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 12)
      .background(backgroundColor)
      .cornerRadius(DesignSystem.Dimensions.buttonCornerRadius)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .onHover { hovering in
      withAnimation(.easeInOut(duration: 0.2)) {
        isHovered = hovering
      }
    }
    .help(NSLocalizedString(hintKey, comment: ""))
  }
  
  /// 创建图标视图
  private func makeIconView() -> some View {
    Image(systemName: iconName)
      .font(.system(size: DesignSystem.Dimensions.methodIconSize))
      .foregroundColor(iconColor)
      .symbolRenderingMode(.hierarchical)
  }
  
  /// 创建标题视图
  private func makeTitleView() -> some View {
    Text(title)
      .font(DesignSystem.Typography.bodyRegular)
      .foregroundColor(titleColor)
  }
  
  /// 处理按钮点击事件
  private func handleButtonTap() {
    withAnimation(.easeOut(duration: 0.1)) {
      isPressed = true
    }
    
    // 触觉反馈
    NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .default)
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      withAnimation(.easeOut(duration: 0.1)) {
        isPressed = false
      }
      action?()
    }
  }
}

#if DEBUG
struct AddMethodButton_Previews: PreviewProvider {
  static var previews: some View {
    AddMethodButton(
      iconName: "doc.text.fill",
      title: "从剪贴板导入",
      hintKey: "hint.clipboard_import"
    )
    .padding()
    .previewLayout(.sizeThatFits)
  }
}
#endif

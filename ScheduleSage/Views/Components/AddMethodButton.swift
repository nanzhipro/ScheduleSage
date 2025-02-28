//
//  AddMethodButton.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024/03/26.
//

import SwiftUI

/// 添加方法按钮组件
/// 提供一个可点击的方法选择按钮，包含图标和文本
struct AddMethodButton: View {
  let iconName: String
  let title: String
  let hintKey: String
  let action: (() -> Void)?
  
  @State private var isHovered = false
  @State private var isPressed = false
  @Environment(\.colorScheme) private var colorScheme
  
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
  
  private var backgroundColor: Color {
    if isPressed {
      return DesignSystem.Colors.primary.opacity(0.1)
    } else if isHovered {
      return DesignSystem.Colors.primary.opacity(0.05)
    }
    return .clear
  }
  
  private var iconColor: Color {
    if isHovered {
      return DesignSystem.Colors.primary.opacity(0.8)
    }
    return DesignSystem.Colors.primary.opacity(0.8)
  }
  
  private var titleColor: Color {
    if isHovered {
      return DesignSystem.Colors.primaryText
    }
    return DesignSystem.Colors.primaryText
  }
  
  var body: some View {
    Button(action: handleButtonTap) {
      VStack(spacing: 12) {
        makeIconView()
        makeTitleView()
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 16)
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
    .withHoverEffect(scale: 1.02, brightness: 0)
    .help(NSLocalizedString(hintKey, comment: ""))
  }
  
  private func makeIconView() -> some View {
    Image(systemName: iconName)
      .font(.system(size: DesignSystem.Dimensions.largeMethodIconSize))
      .foregroundColor(iconColor)
      .symbolRenderingMode(.hierarchical)
  }
  
  private func makeTitleView() -> some View {
    Text(title)
      .font(DesignSystem.Typography.bodyMedium)
      .foregroundColor(titleColor)
  }
  
  private func handleButtonTap() {
    withAnimation(.easeOut(duration: 0.1)) {
      isPressed = true
    }
    
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

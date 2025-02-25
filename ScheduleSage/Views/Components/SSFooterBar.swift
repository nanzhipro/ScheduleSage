//
//  SSFooterBar.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-05-15.
//

import SwiftUI

/// 底部工具栏组件
/// 提供一个包含中心文本和可选操作按钮的底部工具栏
struct SSFooterBar<LeadingContent: View, TrailingContent: View>: View {
  // 中心文本
  let centerText: String
  // 前导内容构建器
  let leadingContent: () -> LeadingContent
  // 尾随内容构建器
  let trailingContent: () -> TrailingContent
  // 内边距
  let padding: EdgeInsets
  
  /// 初始化底部工具栏
  /// - Parameters:
  ///   - centerText: 中心文本
  ///   - padding: 内边距，默认为标准内边距
  ///   - leadingContent: 前导内容构建器
  ///   - trailingContent: 尾随内容构建器
  init(
    centerText: String,
    padding: EdgeInsets? = nil,
    @ViewBuilder leadingContent: @escaping () -> LeadingContent,
    @ViewBuilder trailingContent: @escaping () -> TrailingContent
  ) {
    self.centerText = centerText
    self.padding = padding ?? EdgeInsets(
      top: 0,
      leading: 16,
      bottom: 24,
      trailing: 16
    )
    self.leadingContent = leadingContent
    self.trailingContent = trailingContent
  }
  
  var body: some View {
    ZStack {
      // 中心文本
      VStack(spacing: 4) {
        Text(centerText)
          .font(DesignSystem.Typography.caption)
          .foregroundColor(DesignSystem.Colors.tertiaryText)
      }
      .frame(maxWidth: .infinity)
      
      // 两侧内容
      HStack {
        leadingContent()
        Spacer()
        trailingContent()
      }
    }
    .padding(.horizontal, padding.leading)
    .padding(.bottom, padding.bottom)
    .padding(.top, padding.top)
  }
}

// MARK: - 便利初始化方法
extension SSFooterBar {
  /// 仅带中心文本的底部工具栏
  /// - Parameters:
  ///   - centerText: 中心文本
  ///   - padding: 内边距
  init(
    centerText: String,
    padding: EdgeInsets? = nil
  ) where LeadingContent == EmptyView, TrailingContent == EmptyView {
    self.init(
      centerText: centerText,
      padding: padding,
      leadingContent: { EmptyView() },
      trailingContent: { EmptyView() }
    )
  }
  
  /// 带中心文本和尾随内容的底部工具栏
  /// - Parameters:
  ///   - centerText: 中心文本
  ///   - padding: 内边距
  ///   - trailingContent: 尾随内容构建器
  init(
    centerText: String,
    padding: EdgeInsets? = nil,
    @ViewBuilder trailingContent: @escaping () -> TrailingContent
  ) where LeadingContent == EmptyView {
    self.init(
      centerText: centerText,
      padding: padding,
      leadingContent: { EmptyView() },
      trailingContent: trailingContent
    )
  }
  
  /// 带中心文本和前导内容的底部工具栏
  /// - Parameters:
  ///   - centerText: 中心文本
  ///   - padding: 内边距
  ///   - leadingContent: 前导内容构建器
  init(
    centerText: String,
    padding: EdgeInsets? = nil,
    @ViewBuilder leadingContent: @escaping () -> LeadingContent
  ) where TrailingContent == EmptyView {
    self.init(
      centerText: centerText,
      padding: padding,
      leadingContent: leadingContent,
      trailingContent: { EmptyView() }
    )
  }
}

// MARK: - 反馈按钮
struct SSFeedbackButton: View {
  let url: String
  let title: String
  let hint: String
  
  @State private var scale: CGFloat = 1.0
  
  init(
    url: String,
    title: String = NSLocalizedString("settings_feedback", comment: ""),
    hint: String = NSLocalizedString("feedback_button_hint", comment: "")
  ) {
    self.url = url
    self.title = title
    self.hint = hint
  }
  
  var body: some View {
    Button(action: {
      if let url = URL(string: url) {
        NSWorkspace.shared.open(url)
      }
    }) {
      Text(title)
        .font(DesignSystem.Typography.caption)
        .foregroundColor(DesignSystem.Colors.primary)
    }
    .buttonStyle(.plain)
    .contentShape(Rectangle())
    .help(hint)
    .scaleEffect(scale)
    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: scale)
    .onHover { isHovered in
      withAnimation {
        scale = isHovered ? 1.1 : 1.0
      }
    }
  }
}

#if DEBUG
struct SSFooterBar_Previews: PreviewProvider {
  static var previews: some View {
    VStack {
      Spacer()
      
      // 仅中心文本
      SSFooterBar<EmptyView, EmptyView>(centerText: "Powered by Tencent")
        .background(Color.gray.opacity(0.1))
        .previewDisplayName("Center Text Only")
      
      // 带反馈按钮
      SSFooterBar<EmptyView, SSFeedbackButton>(
        centerText: "Powered by Tencent"
      ) {
        SSFeedbackButton(url: "https://example.com/feedback")
      }
      .background(Color.gray.opacity(0.1))
      .previewDisplayName("With Trailing Content")
      
      // 完整示例
      SSFooterBar(
        centerText: "Powered by Tencent",
        leadingContent: {
          Button("设置") {}
            .buttonStyle(.plain)
        },
        trailingContent: {
          SSFeedbackButton(url: "https://example.com/feedback")
        }
      )
      .background(Color.gray.opacity(0.1))
      .previewDisplayName("Complete Example")
    }
    .frame(height: 200)
    .previewLayout(.sizeThatFits)
  }
}
#endif 
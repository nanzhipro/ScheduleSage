//
//  SSAddMethodSection.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-05-15.
//

import SwiftUI

/// 添加方法区域组件
/// 提供一个包含多个添加方法按钮的区域
struct SSAddMethodSection: View {
  // 按钮配置数组
  let buttons: [ButtonConfig]
  // 按钮之间的间距
  let spacing: CGFloat
  // 按钮高度
  let height: CGFloat
  
  /// 初始化添加方法区域
  /// - Parameters:
  ///   - buttons: 按钮配置数组
  ///   - spacing: 按钮之间的间距，默认为24
  ///   - height: 按钮高度，默认为DesignSystem.Dimensions.largeButtonHeight
  init(
    buttons: [ButtonConfig],
    spacing: CGFloat = 24,
    height: CGFloat = DesignSystem.Dimensions.largeButtonHeight
  ) {
    self.buttons = buttons
    self.spacing = spacing
    self.height = height
  }
  
  var body: some View {
    HStack(spacing: spacing) {
      ForEach(buttons) { config in
        AddMethodButton(
          iconName: config.iconName,
          title: config.title,
          hintKey: config.hintKey,
          action: config.action
        )
        .sheet(isPresented: config.sheetBinding ?? .constant(false)) {
          if let content = config.sheetContent {
            content
          }
        }
      }
    }
    .frame(height: height)
  }
  
  /// 按钮配置
  struct ButtonConfig: Identifiable {
    let id = UUID()
    let iconName: String
    let title: String
    let hintKey: String
    let action: () -> Void
    let sheetBinding: Binding<Bool>?
    let sheetContent: AnyView?
    
    /// 初始化按钮配置
    /// - Parameters:
    ///   - iconName: 图标名称
    ///   - title: 按钮标题
    ///   - hintKey: 提示文本键
    ///   - action: 按钮点击事件
    ///   - sheetBinding: 弹出表单绑定
    ///   - sheetContent: 弹出表单内容
    init(
      iconName: String,
      title: String,
      hintKey: String,
      action: @escaping () -> Void,
      sheetBinding: Binding<Bool>? = nil,
      sheetContent: AnyView? = nil
    ) {
      self.iconName = iconName
      self.title = title
      self.hintKey = hintKey
      self.action = action
      self.sheetBinding = sheetBinding
      self.sheetContent = sheetContent
    }
    
    /// 使用视图构建器初始化按钮配置
    /// - Parameters:
    ///   - iconName: 图标名称
    ///   - title: 按钮标题
    ///   - hintKey: 提示文本键
    ///   - action: 按钮点击事件
    ///   - sheetBinding: 弹出表单绑定
    ///   - sheetContent: 弹出表单内容构建器
    init<Content: View>(
      iconName: String,
      title: String,
      hintKey: String,
      action: @escaping () -> Void,
      sheetBinding: Binding<Bool>,
      @ViewBuilder sheetContent: @escaping () -> Content
    ) {
      self.iconName = iconName
      self.title = title
      self.hintKey = hintKey
      self.action = action
      self.sheetBinding = sheetBinding
      self.sheetContent = AnyView(sheetContent())
    }
  }
}

// MARK: - 便利初始化方法
extension SSAddMethodSection {
  /// 使用剪贴板导入、手动输入和图片导入按钮初始化
  /// - Parameters:
  ///   - viewModel: 视图模型
  ///   - manualInputSheetBinding: 手动输入表单绑定
  ///   - manualInputContent: 手动输入内容构建器
  init(
    viewModel: AddScheduleViewModel,
    manualInputSheetBinding: Binding<Bool>,
    @ViewBuilder manualInputContent: @escaping ([CalendarEvent]) -> some View
  ) {
    let buttons: [ButtonConfig] = [
      // 剪贴板导入
      ButtonConfig(
        iconName: "doc.text.fill",
        title: NSLocalizedString("clipboard_import", comment: ""),
        hintKey: "hint.clipboard_import",
        action: viewModel.checkClipboardContent
      ),
      
      // 手动输入
      ButtonConfig(
        iconName: "pencil.and.list.clipboard",
        title: NSLocalizedString("manual_input", comment: ""),
        hintKey: "hint.manual_input",
        action: { manualInputSheetBinding.wrappedValue = true },
        sheetBinding: manualInputSheetBinding,
        sheetContent: AnyView(
          ManualScheduleInputView(
            isPresented: manualInputSheetBinding,
            llmProcessor: viewModel.llmProcessor,
            viewModel: viewModel,
            onEventsProcessed: { events in
              viewModel.parsedEvents = events
              viewModel.showEventList = true
              manualInputContent(events)
            }
          )
        )
      ),
      
      // 图片导入
      ButtonConfig(
        iconName: "photo.fill",
        title: NSLocalizedString("image_import", comment: ""),
        hintKey: "hint.image_import",
        action: viewModel.handleImageSelection
      )
    ]
    
    self.init(buttons: buttons)
  }
}

#if DEBUG
struct SSAddMethodSection_Previews: PreviewProvider {
  static var previews: some View {
    SSAddMethodSection(
      buttons: [
        SSAddMethodSection.ButtonConfig(
          iconName: "doc.text.fill",
          title: "从剪贴板导入",
          hintKey: "hint.clipboard_import",
          action: {}
        ),
        SSAddMethodSection.ButtonConfig(
          iconName: "pencil.and.list.clipboard",
          title: "手动输入",
          hintKey: "hint.manual_input",
          action: {}
        ),
        SSAddMethodSection.ButtonConfig(
          iconName: "photo.fill",
          title: "从图片导入",
          hintKey: "hint.image_import",
          action: {}
        )
      ]
    )
    .padding()
    .previewLayout(.sizeThatFits)
  }
}
#endif 
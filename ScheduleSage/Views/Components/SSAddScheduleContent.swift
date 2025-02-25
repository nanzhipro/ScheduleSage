//
//  SSAddScheduleContent.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-05-15.
//

import SwiftUI

/// 添加日程内容组件
/// 组合日历图标、标题区域和添加方法区域
struct SSAddScheduleContent: View {
  // 视图模型
  @ObservedObject var viewModel: AddScheduleViewModel
  // 弹出高级会员页面绑定
  @Binding var showPaywall: Bool
  // 内容间距配置
  let spacing: SpacingConfig
  
  /// 初始化添加日程内容
  /// - Parameters:
  ///   - viewModel: 视图模型
  ///   - showPaywall: 弹出高级会员页面绑定
  ///   - spacing: 内容间距配置，默认为标准间距
  init(
    viewModel: AddScheduleViewModel,
    showPaywall: Binding<Bool>,
    spacing: SpacingConfig = .standard
  ) {
    self.viewModel = viewModel
    self._showPaywall = showPaywall
    self.spacing = spacing
  }
  
  var body: some View {
    VStack(spacing: 0) {
      // 顶部空间，确保图标不会紧贴边缘
      Spacer()
        .frame(height: spacing.topPadding)
      
      // 日历图标
      SSCalendarIcon(
        animation: convertAnimation(viewModel.dragAnimation),
        showPremiumBadge: viewModel.proStatus.isPro
      )
      .padding(.bottom, spacing.iconToTitle)
      
      // 标题区域
      SSTitleSection(
        title: AppInfo.name,
        subtitle: NSLocalizedString("schedule_add_subtitle", comment: "")
      )
      .padding(.bottom, spacing.titleToActions)
      
      // 添加方法区域
      SSAddMethodSection(
        viewModel: viewModel,
        manualInputSheetBinding: $viewModel.showManualInputSheet
      ) { _ in
        // 事件处理完成后的回调，这里不需要额外操作
      }
      .padding(.horizontal, spacing.methodSectionHorizontal)
      
      Spacer(minLength: 0)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
  
  /// 将视图模型的动画类型转换为日历图标的动画类型
  private func convertAnimation(_ animation: AddScheduleViewModel.DragAnimation) -> SSCalendarIcon.AnimationType {
    switch animation {
    case .none:
      return .none
    case .pulse:
      return .pulse
    case .scale:
      return .scale
    case .bounce:
      return .bounce
    case .glow:
      return .glow
    }
  }
  
  /// 内容间距配置
  struct SpacingConfig {
    let topPadding: CGFloat
    let iconToTitle: CGFloat
    let titleToActions: CGFloat
    let methodSectionHorizontal: CGFloat
    
    /// 紧凑间距
    static let compact = SpacingConfig(
      topPadding: 20,
      iconToTitle: 20,
      titleToActions: 40,
      methodSectionHorizontal: 32
    )
    
    /// 标准间距
    static let standard = SpacingConfig(
      topPadding: 40,
      iconToTitle: 32,
      titleToActions: 64,
      methodSectionHorizontal: 48
    )
    
    /// 宽松间距
    static let loose = SpacingConfig(
      topPadding: 60,
      iconToTitle: 40,
      titleToActions: 80,
      methodSectionHorizontal: 64
    )
  }
}

#if DEBUG
struct SSAddScheduleContent_Previews: PreviewProvider {
  static var previews: some View {
    // 创建预览用的视图模型
    let viewModel = AddScheduleViewModel()
    
    return Group {
      SSAddScheduleContent(
        viewModel: viewModel,
        showPaywall: .constant(false),
        spacing: .compact
      )
      .previewDisplayName("Compact Spacing")
      
      SSAddScheduleContent(
        viewModel: viewModel,
        showPaywall: .constant(false)
      )
      .previewDisplayName("Standard Spacing")
      
      SSAddScheduleContent(
        viewModel: viewModel,
        showPaywall: .constant(false),
        spacing: .loose
      )
      .previewDisplayName("Loose Spacing")
    }
    .previewLayout(.sizeThatFits)
    .frame(height: 600)
    .padding()
  }
}
#endif 
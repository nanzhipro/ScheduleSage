//
//  AddScheduleView.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-02-14.
//

import AppKit
import SwiftUI

/// 添加日程主页面
struct AddScheduleView: View {
  @EnvironmentObject private var viewModel: AddScheduleViewModel
  @State private var needsRefresh = false
  
  var body: some View {
    VStack(spacing: 0) {
      AddScheduleView_Impl(viewModel: viewModel)
        .withLoading()
        .sheet(isPresented: $viewModel.showEventList) {
          EventListView(
            events: viewModel.parsedEvents,
            onAdd: viewModel.resetState,
            onImport: viewModel.importToCalendar,
            onBack: { viewModel.showEventList = false },
            onUpdate: viewModel.updateEvent
          )
          .presentationDetents([.height(DesignSystem.Dimensions.eventListHeight)])
          .presentationDragIndicator(.visible)
          .presentationBackgroundInteraction(.enabled)
        }
    }
    .toast(
      isPresented: $viewModel.showToast,
      type: viewModel.toastType,
      message: viewModel.toastMessage
    )
    .toast(
      isPresented: .init(
        get: { viewModel.importStatus != .none },
        set: { if !$0 { viewModel.importStatus = .none } }
      ),
      type: toastType,
      message: toastMessage
    )
    .onAppear(perform: viewModel.resetState)
    .onDisappear {
      viewModel.handlePopoverDisappear()
    }
    .id(needsRefresh)
    .onReceive(NotificationCenter.default.publisher(for: .themeDidChange)) { _ in
      needsRefresh.toggle()
    }
  }
  
  private var toastType: ToastType {
    switch viewModel.importStatus {
    case .success:
      return .success
    case .failure:
      return .error
    case .importing, .none:
      return .success
    }
  }
  
  private var toastMessage: String {
    switch viewModel.importStatus {
    case .success:
      return NSLocalizedString("import_success", comment: "")
    case .failure(let error):
      return error.localizedDescription
    case .importing, .none:
      return ""
    }
  }
}

// MARK: - Add Schedule View
private struct AddScheduleView_Impl: View {
  @ObservedObject var viewModel: AddScheduleViewModel
  @Environment(\.colorScheme) var colorScheme
  
  var body: some View {
    ZStack {
      // 使用设计系统定义的渐变背景
      DesignSystem.Gradients.containerBackground(colorScheme: colorScheme)
      
      // 内容层
      VStack(spacing: 0) {
        HeaderView(viewModel: viewModel)
        
        DragDropArea(
          isDragging: $viewModel.isDragging,
          isOCRProcessing: $viewModel.isOCRProcessing,
          onDrop: viewModel.handleDropped,
          onDragEntered: viewModel.handleDragEntered,
          onDragExited: viewModel.handleDragExited
        ) {
          AddScheduleContent(viewModel: viewModel)
            .frame(maxHeight: .infinity)
        }
        .padding(.bottom, DesignSystem.Spacing.vertical)
        
        CloseXButton(action: viewModel.closePopover)
          .padding(.horizontal, DesignSystem.Layout.containerPadding.leading)
          .padding(.bottom, DesignSystem.Layout.containerPadding.bottom)
      }
    }
    .frame(
      width: DesignSystem.Dimensions.mainViewWidth,
      height: DesignSystem.Dimensions.mainViewHeight
    )
    .cornerRadius(DesignSystem.Dimensions.containerCornerRadius)
  }
}

// MARK: - Header View
private struct HeaderView: View {
  @ObservedObject var viewModel: AddScheduleViewModel
  @Environment(\.colorScheme) var colorScheme
  
  var body: some View {
    HStack {
      ProStatusView(
        status: viewModel.proStatus,
        onUpgrade: viewModel.showUpgradeSheetAction,
        style: .compact
      )
      .padding(.horizontal, DesignSystem.Layout.statusBarPadding.leading)
      .padding(.vertical, DesignSystem.Layout.statusBarPadding.top)
      
      Spacer()
      
      SettingsButton()
        .foregroundColor(colorScheme == .dark ? 
          DesignSystem.Colors.secondaryText :    // 深色模式下的图标颜色
          DesignSystem.Colors.secondaryGray      // 浅色模式下的图标颜色
        )
        .frame(width: 44, height: 44)
    }
    .frame(height: DesignSystem.Dimensions.headerHeight)
    // 移除固定背景色，使用渐变背景
    .cornerRadius(DesignSystem.Dimensions.headerCornerRadius)
  }
}

// MARK: - Design Constants
private enum Design {
    enum Spacing {
        /// 顶部到图标的间距
        static let topToIcon: CGFloat = 48
        /// 图标到标题的间距
        static let iconToTitle: CGFloat = 24
        /// 标题到副标题的间距
        static let titleToSubtitle: CGFloat = 12
        /// 副标题到操作按钮的间距
        static let subtitleToActions: CGFloat = 40
        /// 操作按钮之间的水平间距
        static let actionButtonsHorizontal: CGFloat = 20
    }
    
    enum Size {
        /// 图标容器尺寸
        static let iconContainerSize: CGFloat = 80
        /// 图标尺寸
        static let iconSize: CGFloat = 32
    }
}

// MARK: - Calendar Icon
private struct CalendarIcon: View {
    let animation: AddScheduleViewModel.DragAnimation
    
    var body: some View {
        ZStack {
            Circle()
                .fill(DesignSystem.Colors.secondaryBackground)
                .frame(width: Design.Size.iconContainerSize, height: Design.Size.iconContainerSize)
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: Design.Size.iconSize))
                .foregroundColor(DesignSystem.Colors.primary)
        }
        .modifier(DragAnimationModifier(animation: animation))
    }
}

// MARK: - Add Schedule Content
private struct AddScheduleContent: View {
    @ObservedObject var viewModel: AddScheduleViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: Design.Spacing.topToIcon)
            
            CalendarIcon(animation: viewModel.dragAnimation)
                .padding(.bottom, Design.Spacing.iconToTitle)
            
            TitleSection()
                .padding(.bottom, Design.Spacing.subtitleToActions)
            
            AddMethodSection(viewModel: viewModel)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, DesignSystem.Layout.containerPadding.leading)
    }
}

// MARK: - Title Section
private struct TitleSection: View {
    var body: some View {
        VStack(spacing: Design.Spacing.titleToSubtitle) {
            Text(AppInfo.displayName)
                .font(DesignSystem.Typography.title)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            Text(NSLocalizedString("schedule_add_subtitle", comment: ""))
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Add Method Section
private struct AddMethodSection: View {
    @ObservedObject var viewModel: AddScheduleViewModel
    
    var body: some View {
        HStack(spacing: Design.Spacing.actionButtonsHorizontal) {
            AddMethodButton(
                iconName: "doc.text.fill",
                title: NSLocalizedString("clipboard_import", comment: ""),
                hintKey: "hint.clipboard_import",
                action: viewModel.checkClipboardContent
            )
            
            AddMethodButton(
                iconName: "square.and.pencil",
                title: NSLocalizedString("manual_input", comment: ""),
                hintKey: "hint.manual_input",
                action: { viewModel.showManualInputSheet = true }
            )
            .sheet(isPresented: $viewModel.showManualInputSheet) {
                ManualScheduleInputView(
                    isPresented: $viewModel.showManualInputSheet,
                    llmProcessor: viewModel.llmProcessor,
                    viewModel: viewModel,
                    onEventsProcessed: { events in
                        viewModel.parsedEvents = events
                        viewModel.showEventList = true
                    }
                )
            }
            
            AddMethodButton(
                iconName: "photo.fill",
                title: NSLocalizedString("image_import", comment: ""),
                hintKey: "hint.image_import",
                action: viewModel.handleImageSelection
            )
        }
    }
}

// MARK: - Drag Animation Modifier
struct DragAnimationModifier: ViewModifier {
  let animation: AddScheduleViewModel.DragAnimation
  
  func body(content: Content) -> some View {
    content.modifier(
      AnimatedContentModifier(animation: animation)
    )
  }
}

private struct AnimatedContentModifier: ViewModifier {
  let animation: AddScheduleViewModel.DragAnimation
  
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

// MARK: - Close Button
private struct CloseXButton: View {
  let action: () -> Void
  
  var body: some View {
    VStack(spacing: 8) {
      Button(action: action) {
        Text(NSLocalizedString("close_popover", comment: ""))
          .font(DesignSystem.Typography.buttonLabel)
          .foregroundColor(DesignSystem.Colors.background)
          .frame(maxWidth: .infinity)
          .frame(height: DesignSystem.Dimensions.buttonHeight)
          .background(
            DesignSystem.Colors.primary
          )
          .cornerRadius(DesignSystem.Dimensions.buttonCornerRadius)
      }
      .buttonStyle(.plain)
      .withHoverEffect(scale: 1.02, brightness: 0)
      
      Text(NSLocalizedString("powered_by_tencent", comment: ""))
        .font(DesignSystem.Typography.caption)
        .foregroundColor(DesignSystem.Colors.tertiaryText)
        .multilineTextAlignment(.center)
    }
    .contentShape(Rectangle())
  }
}

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
  
  var body: some View {
    ZStack {
      // 使用预先混合的实色渐变
      LinearGradient(
        colors: [
          Color(red: 0.95, green: 0.97, blue: 0.98),  // 浅色调
          Color(red: 0.97, green: 0.98, blue: 0.99),  // 中间色调
          DesignSystem.Colors.background               // 底色
        ],
        startPoint: .top,
        endPoint: .bottom
      )
      
      // 2. 内容放在渐变层之上
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
        .foregroundColor(DesignSystem.Colors.secondaryGray)
        .frame(width: 44, height: 44)
    }
    .frame(height: DesignSystem.Dimensions.headerHeight)
    // 移除 HeaderView 的背景色，让渐变色显示出来
    // .background(DesignSystem.Colors.background)
    .cornerRadius(DesignSystem.Dimensions.headerCornerRadius)
  }
}

// MARK: - Add Schedule Content
private struct AddScheduleContent: View {
  @ObservedObject var viewModel: AddScheduleViewModel
  
  var body: some View {
    VStack(spacing: 0) {
      Spacer()
        .frame(height: DesignSystem.Spacing.vertical * 3)
      
      CalendarIcon(animation: viewModel.dragAnimation)
        .padding(.bottom, DesignSystem.Spacing.vertical * 0.5)
      
      TitleSection()
        .padding(.bottom, DesignSystem.Spacing.vertical * 2)
      
      AddMethodSection(viewModel: viewModel)
      
      Spacer()
    }
    .frame(maxWidth: .infinity)
    .padding(.horizontal, DesignSystem.Layout.containerPadding.leading)
  }
}

// MARK: - Calendar Icon
private struct CalendarIcon: View {
  let animation: AddScheduleViewModel.DragAnimation
  
  var body: some View {
    ZStack {
      Circle()
        .fill(DesignSystem.Colors.secondaryBackground)
        .frame(
          width: DesignSystem.Dimensions.emptyStateIconSize,
          height: DesignSystem.Dimensions.emptyStateIconSize
        )
      Image(systemName: "calendar.badge.plus")
        .font(.system(size: 32))
        .foregroundColor(DesignSystem.Colors.primary)
    }
    .modifier(DragAnimationModifier(animation: animation))
  }
}

// MARK: - Title Section
private struct TitleSection: View {
  var body: some View {
    VStack(spacing: 8) {
      Text(AppInfo.displayName)
        .font(DesignSystem.Typography.title)
        .foregroundColor(DesignSystem.Colors.primaryText)
      
      Text(NSLocalizedString("schedule_add_subtitle", comment: ""))
        .font(DesignSystem.Typography.caption)
        .foregroundColor(DesignSystem.Colors.secondaryText)
        .multilineTextAlignment(.center)
    }
  }
}

// MARK: - Add Method Section
private struct AddMethodSection: View {
  @ObservedObject var viewModel: AddScheduleViewModel
  
  var body: some View {
    HStack(spacing: DesignSystem.Spacing.horizontal) {
      AddMethodButton(
        icon: "doc.text.fill",
        text: NSLocalizedString("clipboard_import", comment: ""),
        action: viewModel.checkClipboardContent
      )
      
      AddMethodButton(
        icon: "square.and.pencil",
        text: NSLocalizedString("manual_input", comment: ""),
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
        icon: "photo.fill",
        text: NSLocalizedString("image_import", comment: ""),
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
  }
}

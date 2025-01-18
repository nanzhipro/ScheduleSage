//
//  PopoverView.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-02-14.
//

import AppKit
import SwiftUI

/**
 日程主页面
 */
struct PopoverView: View {
  @EnvironmentObject private var viewModel: PopoverViewModel
  
  var body: some View {
    VStack(spacing: 0) {
      AddScheduleView(viewModel: viewModel)
        .withLoading()
        .sheet(isPresented: $viewModel.showEventList) {
          EventListView(
            proStatus: viewModel.proStatus,
            events: viewModel.parsedEvents,
            onUpgrade: viewModel.showUpgradeSheetAction,
            onAdd: viewModel.resetState,
            onImport: viewModel.importToCalendar,
            onBack: { viewModel.showEventList = false }
          )
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
private struct AddScheduleView: View {
  @ObservedObject var viewModel: PopoverViewModel
  
  var body: some View {
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
      }
    }
    .frame(
      width: ScheduleDesignSystem.Dimensions.containerWidth,
      height: ScheduleDesignSystem.Dimensions.containerHeight
    )
    .background(ScheduleDesignSystem.Colors.background)
    .cornerRadius(ScheduleDesignSystem.Dimensions.containerCornerRadius)
  }
}

// MARK: - Header View
private struct HeaderView: View {
  @ObservedObject var viewModel: PopoverViewModel
  
  var body: some View {
    HStack {
      ProStatusView(
        status: viewModel.proStatus,
        onUpgrade: viewModel.showUpgradeSheetAction,
        style: .compact
      )
      .padding(.horizontal, ScheduleDesignSystem.Layout.statusBarPadding.leading)
      .padding(.vertical, ScheduleDesignSystem.Layout.statusBarPadding.top)
      
      Spacer()
      
      SettingsButton()
        .foregroundColor(ScheduleDesignSystem.Colors.secondaryGray)
        .frame(width: 44, height: 44)
    }
    .frame(height: ScheduleDesignSystem.Dimensions.headerHeight)
    .background(ScheduleDesignSystem.Colors.background)
    .cornerRadius(ScheduleDesignSystem.Dimensions.headerCornerRadius)
  }
}

// MARK: - Add Schedule Content
private struct AddScheduleContent: View {
  @ObservedObject var viewModel: PopoverViewModel
  
  var body: some View {
    VStack(spacing: 0) {
      Spacer()
        .frame(height: ScheduleDesignSystem.Spacing.vertical * 2)
      
      CalendarIcon(animation: viewModel.dragAnimation)
        .padding(.bottom, ScheduleDesignSystem.Spacing.vertical * 1.5)
      
      TitleSection()
        .padding(.bottom, ScheduleDesignSystem.Spacing.vertical * 2)
      
      AddMethodSection(viewModel: viewModel)
      
      Spacer()
    }
    .frame(maxWidth: .infinity)
    .padding(.horizontal, ScheduleDesignSystem.Layout.containerPadding.leading)
  }
}

// MARK: - Calendar Icon
private struct CalendarIcon: View {
  let animation: PopoverViewModel.DragAnimation
  
  var body: some View {
    ZStack {
      Circle()
        .fill(ScheduleDesignSystem.Colors.lightGray)
        .frame(
          width: ScheduleDesignSystem.Dimensions.emptyStateIconSize,
          height: ScheduleDesignSystem.Dimensions.emptyStateIconSize
        )
      Image(systemName: "calendar.badge.plus")
        .font(.system(size: 32))
        .foregroundColor(ScheduleDesignSystem.Colors.iconGray)
    }
    .modifier(DragAnimationModifier(animation: animation))
  }
}

// MARK: - Title Section
private struct TitleSection: View {
  var body: some View {
    VStack(spacing: 8) {
      Text(NSLocalizedString("schedule_add_title", comment: ""))
        .font(ScheduleDesignSystem.Typography.title)
        .foregroundColor(ScheduleDesignSystem.Colors.primaryText)
      
      Text(NSLocalizedString("schedule_add_subtitle", comment: ""))
        .font(ScheduleDesignSystem.Typography.caption)
        .foregroundColor(ScheduleDesignSystem.Colors.secondaryText)
        .multilineTextAlignment(.center)
    }
  }
}

// MARK: - Add Method Section
private struct AddMethodSection: View {
  @ObservedObject var viewModel: PopoverViewModel
  
  var body: some View {
    HStack(spacing: ScheduleDesignSystem.Spacing.horizontal) {
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
          onEventsProcessed: { events in
            viewModel.parsedEvents = events
            viewModel.showEventList = true
          }
        )
      }
      
      AddMethodButton(
        icon: "photo.fill",
        text: NSLocalizedString("image_import", comment: ""),
        action: {
          ImagePicker(
            onImageSelected: { url in
              print("Selected image path: \(url.path)")
            },
            onError: { error in
              print("Image selection failed with error: \(error.localizedDescription)")
            }
          ).showPicker()
        }
      )
    }
  }
}

// MARK: - Drag Animation Modifier
struct DragAnimationModifier: ViewModifier {
  let animation: PopoverViewModel.DragAnimation
  
  func body(content: Content) -> some View {
    content.modifier(
      AnimatedContentModifier(animation: animation)
    )
  }
}

private struct AnimatedContentModifier: ViewModifier {
  let animation: PopoverViewModel.DragAnimation
  
  func body(content: Content) -> some View {
    content
      .scaleEffect(animation == .pulse ? 1.1 : (animation == .scale ? 1.2 : 1.0))
      .offset(y: animation == .bounce ? -10 : 0)
      .shadow(
        color: animation == .glow ? ScheduleDesignSystem.Colors.primary.opacity(0.5) : .clear,
        radius: animation == .glow ? 20 : 0
      )
      .animation(.spring(response: 0.3, dampingFraction: 0.8), value: animation)
  }
}

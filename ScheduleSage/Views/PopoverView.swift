//
//  PopoverView.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-02-14.
//

import AppKit
import SwiftUI

/**
 日程添加页面
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
    VStack(spacing: ScheduleDesignSystem.Spacing.vertical) {
      Spacer()
        .frame(height: ScheduleDesignSystem.Spacing.vertical)
      
      CalendarIcon(animation: viewModel.dragAnimation)
      
      TitleSection()
      
      AddMethodSection(viewModel: viewModel)
      
      Spacer()
      
      ImportButton(viewModel: viewModel)
    }
    .frame(maxWidth: .infinity)
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
    .padding(.top, ScheduleDesignSystem.Spacing.vertical * 1.5)
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
        text: NSLocalizedString("manual_input", comment: "")
      )
      
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
    .padding(.horizontal, ScheduleDesignSystem.Layout.containerPadding.leading)
    .padding(.top, ScheduleDesignSystem.Spacing.vertical * 1.2)
  }
}

// MARK: - Import Button
private struct ImportButton: View {
  @ObservedObject var viewModel: PopoverViewModel
  
  var body: some View {
    Button(action: { viewModel.showEventList = true }) {
      Text(NSLocalizedString("import_calendar", comment: ""))
        .font(ScheduleDesignSystem.Typography.buttonLabel)
        .foregroundColor(ScheduleDesignSystem.Colors.background)
        .frame(maxWidth: .infinity)
        .frame(height: ScheduleDesignSystem.Dimensions.buttonHeight)
        .background(
          ScheduleDesignSystem.Colors.primary
            .opacity(viewModel.canImport ? 1 : 0.5)
        )
        .cornerRadius(ScheduleDesignSystem.Dimensions.buttonCornerRadius)
    }
    .buttonStyle(.plain)
    .disabled(!viewModel.canImport)
    .withHoverEffect(scale: 1.02, brightness: viewModel.canImport ? 0.05 : 0)
    .padding(.horizontal, ScheduleDesignSystem.Layout.containerPadding.leading)
    .padding(.bottom, ScheduleDesignSystem.Layout.containerPadding.bottom)
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

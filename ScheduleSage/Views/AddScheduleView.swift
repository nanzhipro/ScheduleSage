//
//  AddScheduleView.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-02-14.
//

import AppKit
import SwiftUI
import RevenueCat

/// 添加日程主页面
struct AddScheduleView: View {
  @EnvironmentObject private var viewModel: AddScheduleViewModel
  @EnvironmentObject private var iapService: IAPService
  @State private var showPaywall = false
  @State private var needsRefresh = false
  @Environment(\.colorScheme) private var colorScheme
  
  var body: some View {
    ZStack {
      // 渐变背景
      SSGradientBackground(primaryColorWithStartOpacity: 0.2)
      
      VStack(spacing: 0) {
        // 升级按钮
        HStack {
          Spacer()
          VStack(spacing: 4) {
            SSPremiumButton(action: {
              showPaywall = true
            })
            .padding(.top, 4)
            .padding(.trailing, 12)
          }
        }

        // 主要内容
        AddScheduleView_Impl(viewModel: viewModel, showPaywall: $showPaywall)
          .withLoading()
          .padding(.top, -32)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
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
      .sheet(isPresented: $showPaywall) {
        PaywallView {
          proceedWithProFeature()
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
    }
    .onAppear(perform: viewModel.resetState)
    .id(needsRefresh)
    .onReceive(NotificationCenter.default.publisher(for: .themeDidChange)) { _ in
      needsRefresh.toggle()
    }
    .fileImporter(
      isPresented: $viewModel.showImagePicker,
      allowedContentTypes: ImageSupport.supportedUTTypes,
      allowsMultipleSelection: false
    ) { result in
      viewModel.handleImagePickerResult(result)
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
  
  private func proceedWithProFeature() {
    // 实现具体的 Pro 功能
  }
}

// MARK: - Add Schedule View
private struct AddScheduleView_Impl: View {
  @ObservedObject var viewModel: AddScheduleViewModel
  @Environment(\.colorScheme) var colorScheme
  @Binding var showPaywall: Bool
  
  var body: some View {
    ZStack {
      // 主要内容
      VStack(spacing: 0) {
        // 扩展 DragDropArea 以包含所有内容
        DragDropArea(
          isDragging: $viewModel.isDragging,
          isOCRProcessing: $viewModel.isOCRProcessing,
          onDrop: viewModel.handleDropped,
          onDragEntered: viewModel.handleDragEntered,
          onDragExited: viewModel.handleDragExited
        ) {
          VStack(spacing: 0) {
            // 顶部留白
            Spacer()
              .frame(height: 16)
            
            // 使用组件化的内容区域
            SSAddScheduleContent(viewModel: viewModel, showPaywall: $showPaywall)
              .padding(32)
            
            Spacer()
          }
        }
        .frame(maxHeight: .infinity)
        
        // 底部工具栏
        SSFooterBar<EmptyView, SSFeedbackButton>(
          centerText: NSLocalizedString("powered_by_tencent", comment: "")
        ) {
          SSFeedbackButton(url: AppConstants.URLs.feedback)
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(colorScheme == .dark ? DesignSystem.Colors.background : nil)
  }
}

#if DEBUG
struct AddScheduleView_Previews: PreviewProvider {
  static var previews: some View {
    AddScheduleView()
      .environmentObject(AddScheduleViewModel())
      .environmentObject(IAPService.shared)
      .previewLayout(.sizeThatFits)
  }
}
#endif

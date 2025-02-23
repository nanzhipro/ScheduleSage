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
  @EnvironmentObject private var authViewModel: AuthenticationViewModel
  @State private var showPaywall = false
  @State private var needsRefresh = false
  
  var body: some View {
    ZStack {
      VStack(spacing: 0) {
        AddScheduleView_Impl(viewModel: viewModel, showPaywall: $showPaywall)
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
          .sheet(isPresented: $showPaywall) {
            PaywallView {
              proceedWithProFeature()
            }
          }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
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
      
      // 登录页面覆盖
      if !authViewModel.isAuthenticated {
        LoginView()
          .transition(
            .asymmetric(
              insertion: .opacity.combined(with: .scale(scale: 1.1)),
              removal: .opacity.combined(with: .scale(scale: 0.9))
            )
          )
          .animation(.easeInOut(duration: 0.3), value: authViewModel.isAuthenticated)
      }
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
      // 渐变背景，仅在浅色模式下显示
      if colorScheme == .light {
        LinearGradient(
          colors: [
            DesignSystem.Colors.primary.opacity(0.1),
            DesignSystem.Colors.primary.opacity(0.05),
            DesignSystem.Colors.background
          ],
          startPoint: .top,
          endPoint: .bottom
        )
        .ignoresSafeArea()
      }
      
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
              .frame(height: Design.Spacing.windowTopPadding)
            
            AddScheduleContent(viewModel: viewModel, showPaywall: $showPaywall)
              .padding(Design.Spacing.contentPadding)
            
            Spacer()
          }
        }
        .frame(maxHeight: .infinity)
        
        // 底部工具栏
        ZStack {
          // powered by 文本居中
          Text(NSLocalizedString("powered_by_tencent", comment: ""))
            .font(DesignSystem.Typography.caption)
            .foregroundColor(DesignSystem.Colors.tertiaryText)
            .frame(maxWidth: .infinity)
          
          HStack(spacing: 16) {
            // 添加升级按钮
            Button(action: {
              showPaywall = true
            }) {
              HStack(spacing: 4) {
                Image(systemName: "star.fill")
                  .foregroundColor(.yellow)
                Text(NSLocalizedString("upgrade_to_premium", comment: ""))
                  .font(DesignSystem.Typography.caption)
                  .foregroundColor(DesignSystem.Colors.primary)
              }
            }
            .buttonStyle(.plain)
            .withHoverEffect(scale: 1.1, brightness: 0)
            
            Spacer()
            
            // 反馈按钮
            Button(action: {
              if let url = URL(string: AppConstants.URLs.feedback) {
                NSWorkspace.shared.open(url)
              }
            }) {
              Text(NSLocalizedString("settings_feedback", comment: ""))
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.primary)
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
            .help(NSLocalizedString("feedback_button_hint", comment: ""))
            .scaleEffect(viewModel.feedbackButtonScale)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: viewModel.feedbackButtonScale)
            .onHover { isHovered in
              withAnimation {
                viewModel.feedbackButtonScale = isHovered ? 1.1 : 1.0
              }
            }
            
            // 设置按钮
            SettingsButton()
              .foregroundColor(colorScheme == .dark ? 
                DesignSystem.Colors.secondaryText :
                DesignSystem.Colors.secondaryGray
              )
              .frame(width: 44, height: 44)
          }
          .padding(.horizontal, Design.Spacing.bottomBarPadding.horizontal)
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(colorScheme == .dark ? DesignSystem.Colors.background : nil)
  }
}

// MARK: - Design Constants
private enum Design {
  enum Spacing {
    /// 窗口顶部间距
    static let windowTopPadding: CGFloat = 32
    
    /// 底部工具栏内边距
    static let bottomBarPadding = (
      horizontal: 16.0,
      bottom: 12.0
    )
    
    /// 内容整体内边距
    static let contentPadding: CGFloat = 32
    
    /// 拖拽区域顶部到图标的间距
    static let dragAreaTopPadding: CGFloat = 40
    
    /// 图标到标题的间距
    static let iconToTitle: CGFloat = 32
    /// 标题到副标题的间距
    static let titleToSubtitle: CGFloat = 12
    /// 标题到操作按钮的间距
    static let titleToActions: CGFloat = 48
    /// 操作按钮之间的水平间距
    static let actionButtonsHorizontal: CGFloat = 24
    /// 方法选择区域水平内边距
    static let methodSectionHorizontal: CGFloat = 48
    /// 内容区底部间距
    static let contentBottomPadding: CGFloat = 32
  }
  
  enum Size {
    /// 图标容器尺寸
    static let iconContainerSize: CGFloat = 100
    /// 图标尺寸
    static let iconSize: CGFloat = 48
  }
}

// MARK: - Calendar Icon
private struct CalendarIcon: View {
    let animation: AddScheduleViewModel.DragAnimation
    @EnvironmentObject private var iapService: IAPService
    
    var body: some View {
        ZStack {
            // 基础日历图标
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.secondaryBackground)
                    .frame(width: Design.Size.iconContainerSize, height: Design.Size.iconContainerSize)
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: Design.Size.iconSize))
                    .foregroundColor(DesignSystem.Colors.primary)
            }
            .modifier(DragAnimationModifier(animation: animation))
            
            // Pro 用户的皇冠标识
            if iapService.isPremium {
                Image(systemName: "crown.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.yellow)
                    .shadow(color: .yellow.opacity(0.3), radius: 4)
                    .offset(y: -Design.Size.iconContainerSize/2 - 10)
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }
}

// MARK: - Add Schedule Content
private struct AddScheduleContent: View {
  @ObservedObject var viewModel: AddScheduleViewModel
  @Binding var showPaywall: Bool
  
  var body: some View {
    VStack(spacing: 0) {
      // 顶部空间，确保图标不会紧贴边缘
      Spacer()
        .frame(height: Design.Spacing.dragAreaTopPadding)
      
      CalendarIcon(animation: viewModel.dragAnimation)
        .padding(.bottom, Design.Spacing.iconToTitle)
      
      TitleSection()
        .padding(.bottom, Design.Spacing.titleToActions)
      
      AddMethodSection(viewModel: viewModel, showPaywall: $showPaywall)
        .padding(.horizontal, Design.Spacing.methodSectionHorizontal)
      
      Spacer(minLength: 0)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

// MARK: - Title Section
private struct TitleSection: View {
    var body: some View {
        VStack(spacing: 12) {
            Text(AppInfo.name)
                .font(DesignSystem.Typography.title)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            Text(NSLocalizedString("schedule_add_subtitle", comment: ""))
                .font(DesignSystem.Typography.largeHeaderSubtitle)
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Add Method Section
private struct AddMethodSection: View {
    @ObservedObject var viewModel: AddScheduleViewModel
    @EnvironmentObject private var iapService: IAPService
    @Binding var showPaywall: Bool
    
    var body: some View {
        HStack(spacing: Design.Spacing.actionButtonsHorizontal) {
            AddMethodButton(
                iconName: "doc.text.fill",
                title: NSLocalizedString("clipboard_import", comment: ""),
                hintKey: "hint.clipboard_import",
                action: viewModel.checkClipboardContent
            )
            
            AddMethodButton(
                iconName: "pencil.and.list.clipboard",
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
        .frame(height: DesignSystem.Dimensions.largeButtonHeight)
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

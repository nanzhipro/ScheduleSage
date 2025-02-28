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
  @State private var showSettings = false
  @State private var needsRefresh = false
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.openSettings) private var openSettings
  
  private var isModernMacOS: Bool {
    if #available(macOS 14.0, *) {
      return true
    }
    return false
  }
  
  var body: some View {
    ZStack {
      // 渐变背景，仅在浅色模式下显示
      if colorScheme == .light {
        LinearGradient(
          colors: [
            DesignSystem.Colors.primary.opacity(0.2),
            DesignSystem.Colors.primary.opacity(0.1),
            DesignSystem.Colors.background
          ],
          startPoint: .top,
          endPoint: .bottom
        )
        .ignoresSafeArea()
      }
      
      VStack(spacing: 0) {
        AddScheduleView_Impl(viewModel: viewModel)
          .withLoading()
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
      .sheet(isPresented: $viewModel.showPaywall) {
        PaywallView {
          viewModel.proceedWithProFeature()
        }
      }
      // 仅在旧版 macOS 上使用 sheet
      .sheet(isPresented: $showSettings) {
        if !isModernMacOS {
          SettingsView()
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
    .toolbar {
      ToolbarItemGroup(placement: .automatic) {
        Spacer()
        UpgradePremiumButton(viewModel: viewModel)
        Button(action: {
          if isModernMacOS {
            openSettings()
          } else {
            showSettings = true
          }
        }) {
          Image(systemName: "gearshape.fill")
            .foregroundColor(DesignSystem.Colors.primary)
            .font(DesignSystem.Typography.caption)
        }
        .buttonStyle(.plain)
        .withHoverEffect(scale: 1.1, brightness: 0)
        .help(NSLocalizedString("settings_button_hint", comment: ""))
        .padding(.trailing, 16)
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
              .frame(height: Design.Spacing.windowTopPadding)
            
            AddScheduleContent(viewModel: viewModel)
              .padding(Design.Spacing.contentPadding)
            
            Spacer()
          }
        }
        .frame(maxHeight: .infinity)
        .padding(.top, 8)
        
        // 底部工具栏
        ZStack {
          // powered by 文本居中
          VStack(spacing: 4) {
            Text(NSLocalizedString("powered_by_tencent", comment: ""))
              .font(DesignSystem.Typography.caption)
              .foregroundColor(DesignSystem.Colors.secondaryText)
              .padding(.vertical, 16)
          }
          .frame(maxWidth: .infinity)
          
          // 帮助中心按钮靠右对齐
          HStack {
            Spacer()
            HelpCenterButton()
              .padding(.trailing, 20)
          }
        }
        .frame(maxWidth: .infinity)
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
    static let windowTopPadding: CGFloat = 16
    
    /// 底部工具栏内边距
    static let bottomBarPadding = (
      horizontal: 16.0,
      bottom: 24.0
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
    static let titleToActions: CGFloat = 64
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
  
  var body: some View {
    VStack(spacing: 0) {
      // 顶部空间，确保图标不会紧贴边缘
      Spacer()
        .frame(height: Design.Spacing.dragAreaTopPadding)
      
      CalendarIcon(animation: viewModel.dragAnimation)
        .padding(.bottom, Design.Spacing.iconToTitle)
      
      TitleSection()
        .padding(.bottom, Design.Spacing.titleToActions)
      
      AddMethodSection(viewModel: viewModel)
        .padding(.horizontal, Design.Spacing.methodSectionHorizontal)
      
      Spacer(minLength: 0)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

// MARK: - Title Section
private struct TitleSection: View {
    @State private var isHovered = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: Design.Spacing.titleToSubtitle) {
            // 主标题
            Text(AppInfo.name)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            DesignSystem.Colors.primary,
                            DesignSystem.Colors.primary.opacity(0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(
                    color: colorScheme == .dark ? 
                        DesignSystem.Colors.primary.opacity(0.3) : 
                        .clear,
                    radius: isHovered ? 15 : 10
                )
                .scaleEffect(isHovered ? 1.05 : 1.0)
            
            // 副标题
            Text(NSLocalizedString("schedule_add_subtitle", comment: ""))
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .opacity(isHovered ? 0.9 : 0.8)
                .animation(.easeInOut(duration: 0.2), value: isHovered)
        }
        .padding(.horizontal)
        .contentShape(Rectangle())
    }
}

// MARK: - Add Method Section
private struct AddMethodSection: View {
    @ObservedObject var viewModel: AddScheduleViewModel
    @EnvironmentObject private var iapService: IAPService
    
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

// MARK: - Upgrade Premium Button
private struct UpgradePremiumButton: View {
  @ObservedObject var viewModel: AddScheduleViewModel
  @EnvironmentObject private var iapService: IAPService
  
  private var buttonText: LocalizedStringKey {
    iapService.isPremium ? "subscribed_status" : "upgrade_to_premium"
  }
  
  var body: some View {
    Button(action: {
      // 无论是否是会员，都显示 Paywall
      viewModel.showPaywall = true
    }) {
      HStack(spacing: 4) {
        Image(systemName: "sparkles")
          .foregroundColor(.yellow)
        Text(buttonText)
          .font(DesignSystem.Typography.caption)
          .foregroundColor(iapService.isPremium ? .green : DesignSystem.Colors.primary)
      }
      .padding(.vertical, 6)
      .padding(.horizontal, 12)
    }
    .buttonStyle(.plain)
    .withHoverEffect(scale: 1.1, brightness: 0)
    .help(NSLocalizedString(iapService.isPremium ? "subscribed_hint" : "upgrade_button_hint", comment: ""))
  }
}

// MARK: - Help Center Button
private struct HelpCenterButton: View {
  @Environment(\.colorScheme) private var colorScheme
  @State private var isHovered = false
  @State private var isPressed = false
  
  var body: some View {
    Button {
      // 添加触感反馈
      NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .default)
      
      // 打开 FAQ 页面
      if let url = URL(string: AppConstants.URLs.faq) {
        NSWorkspace.shared.open(url)
      }
    } label: {
      Image(systemName: "questionmark.circle.fill")
        .font(.system(size: 20))  // 调整大小以匹配文本
        .foregroundStyle(
          LinearGradient(
            colors: [
              DesignSystem.Colors.primary,
              DesignSystem.Colors.primary.opacity(0.8)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
        .background(
          Circle()
            .fill(colorScheme == .dark ? 
                Color.black.opacity(0.3) : 
                Color.white.opacity(0.8))
            .shadow(
              color: colorScheme == .dark ?
                DesignSystem.Colors.primary.opacity(isHovered ? 0.4 : 0.3) :
                DesignSystem.Colors.primary.opacity(isHovered ? 0.3 : 0.2),
              radius: isHovered ? 8 : 6,
              x: 0,
              y: colorScheme == .dark ? 1 : 2
            )
        )
        .scaleEffect(isPressed ? 0.95 : (isHovered ? 1.05 : 1.0))
        .padding(.vertical, 16)  // 添加垂直内边距以对齐文本
    }
    .buttonStyle(.plain)
    .onHover { hovering in
      withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
        isHovered = hovering
      }
    }
    .pressEvents(onPress: {
      withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
        isPressed = true
      }
    }, onRelease: {
      withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
        isPressed = false
      }
    })
  }
}

// MARK: - Press Event Modifier
private struct PressEventsModifier: ViewModifier {
  var onPress: () -> Void
  var onRelease: () -> Void
  
  func body(content: Content) -> some View {
    content
      .simultaneousGesture(
        DragGesture(minimumDistance: 0)
          .onChanged { _ in
            onPress()
          }
          .onEnded { _ in
            onRelease()
          }
      )
  }
}

extension View {
  fileprivate func pressEvents(
    onPress: @escaping () -> Void,
    onRelease: @escaping () -> Void
  ) -> some View {
    modifier(PressEventsModifier(onPress: onPress, onRelease: onRelease))
  }
}

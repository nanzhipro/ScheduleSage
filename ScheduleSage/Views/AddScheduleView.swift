//
//  AddScheduleView.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-02-14.
//

import AppKit
import RevenueCat
import SwiftUI

/// 定义应用中的视图层级常量
enum ZIndex {
  /// 背景层 - 最底层
  static let background = 1
  /// 中间层 - 位于背景之上，内容之下
  static let midLayer = 2
  /// 内容层 - 主要交互元素
  static let content = 3
  /// 顶层 - 最高优先级元素
  static let topLayer = 4

  /// 拖拽状态下的提升层级
  static let dragElevated = 10
  /// 弹窗层级
  static let modal = 20
  /// 全局提示层级
  static let toast = 30
}

/// 添加日程主页面 | 首页
struct AddScheduleView: View {
  @EnvironmentObject private var viewModel: AddScheduleViewModel
  @State private var showSettings = false
  @State private var needsRefresh = false
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.openSettings) private var openSettings

  var body: some View {
    ZStack {
      // 渐变背景，仅在浅色模式下显示
      BackgroundView(colorScheme: colorScheme)
        .zIndex(Double(ZIndex.background))  // 背景层级最低

      VStack(spacing: 0) {
        MainContentView(viewModel: viewModel)
          .withLoading()
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .sheet(isPresented: $viewModel.showEventList) {
        EventListSheet(viewModel: viewModel)
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
        message: viewModel.toastMessage,
        position: .center
      )
      .toast(
        isPresented: .init(
          get: { viewModel.importStatus != .none },
          set: { if !$0 { viewModel.importStatus = .none } }
        ),
        type: toastType,
        message: toastMessage,
        position: .center
      )
      .zIndex(Double(ZIndex.content))  // 主内容区域在背景之上
    }
    .toolbar {
      ToolbarItemGroup(placement: .automatic) {
        Spacer()
        UpgradePremiumButton(viewModel: viewModel)
        SettingsButton(
          isModernMacOS: isModernMacOS,
          openSettings: openSettings,
          showSettings: $showSettings
        )
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

  private var isModernMacOS: Bool {
    if #available(macOS 14.0, *) {
      return true
    }
    return false
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

// MARK: - Background View
private struct BackgroundView: View {
  let colorScheme: ColorScheme

  var body: some View {
    if colorScheme == .light {
      LinearGradient(
        colors: [
          DesignSystem.Colors.primary.opacity(0.1),
          DesignSystem.Colors.background,
        ],
        startPoint: .top,
        endPoint: .bottom
      )
      .ignoresSafeArea()
    } else {
      // 深色模式下的背景
      LinearGradient(
        colors: [
          DesignSystem.Colors.primary.opacity(0.05),
          DesignSystem.Colors.background,
        ],
        startPoint: .top,
        endPoint: .bottom
      )
      .ignoresSafeArea()
    }
  }
}

// MARK: - Settings Button
private struct SettingsButton: View {
  let isModernMacOS: Bool
  let openSettings: OpenSettingsAction
  @Binding var showSettings: Bool

  var body: some View {
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

// MARK: - Event List Sheet
private struct EventListSheet: View {
  @ObservedObject var viewModel: AddScheduleViewModel

  var body: some View {
    EventListView(
      events: viewModel.parsedEvents,
      onAdd: viewModel.resetState,
      onImport: { selectedEventIds in
        viewModel.importToCalendar(selectedEventIds: selectedEventIds)
      },
      onBack: { viewModel.showEventList = false },
      onUpdate: viewModel.updateEvent,
      viewModel: viewModel
    )
    .presentationDetents([.height(DesignSystem.Dimensions.eventListHeight)])
    .presentationDragIndicator(.visible)
    .presentationBackgroundInteraction(.enabled)
  }
}

// MARK: - Main Content View
private struct MainContentView: View {
  @ObservedObject var viewModel: AddScheduleViewModel
  @Environment(\.colorScheme) var colorScheme

  var body: some View {
    ZStack(alignment: .center) {
      // 日历事件流背景 - 放在背景之上，主内容之下，居中显示
      CalendarFeedsBackgroundView()
        .zIndex(Double(ZIndex.midLayer))  // 日历事件流背景在基础背景之上

      // 主内容区域
      VStack(spacing: 0) {
        DragDropArea(
          isDragging: $viewModel.isDragging,
          isOCRProcessing: $viewModel.isOCRProcessing,
          onDrop: viewModel.handleDropped,
          onDragEntered: viewModel.handleDragEntered,
          onDragExited: viewModel.handleDragExited
        ) {
          VStack(spacing: 0) {
            Spacer()
              .frame(height: Design.Spacing.windowTopPadding)

            AddScheduleContent(viewModel: viewModel)
              .padding(Design.Spacing.contentPadding)

            Spacer()
          }
        }
        .frame(maxHeight: .infinity)
        .padding(.top, 8)

        // 底部留出空间给悬浮面板
        Spacer()
          .frame(height: 16)

        FooterView()
      }
      .zIndex(Double(ZIndex.background))  // 主内容在底层

      // 使用 VStack 将悬浮操作面板放置在底部
      VStack {
        Spacer()  // 将面板推到底部

        // 悬浮操作面板
        FloatingActionPanel(
          viewModel: viewModel,
          onSendText: { text in
            Task {
              do {
                LoadingManager.shared.show(.processing)
                let events = try await viewModel.processManualInput(text)
                viewModel.parsedEvents = events
                viewModel.showEventList = true
                LoadingManager.shared.hide()
              } catch {
                LoadingManager.shared.hide()
                viewModel.showToast = true
                viewModel.toastType = .error
                viewModel.toastMessage = error.localizedDescription
              }
            }
          }
        )
        .padding(.horizontal, 80)
        .padding(.bottom, 60)
      }
      .zIndex(Double(ZIndex.midLayer))  // 悬浮面板在主内容之上
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    // 移除深色模式下的不透明背景，改为使用透明背景
    .background(Color.clear)
    .sheet(isPresented: $viewModel.showManualInputSheet) {
      ManualInputSheet(viewModel: viewModel)
    }
  }
}

// MARK: - Footer View
private struct FooterView: View {
  var body: some View {
    ZStack {
      // powered by 文本居中
      VStack(spacing: 4) {
        Text(NSLocalizedString("powered_by_tencent", comment: ""))
          .font(DesignSystem.Typography.caption)
          .foregroundColor(DesignSystem.Colors.secondaryText)
          .padding(.vertical, 8)
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
    .padding(.bottom, 4)
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
    static let contentPadding: CGFloat = 12

    /// 拖拽区域顶部到图标的间距
    static let dragAreaTopPadding: CGFloat = 40

    /// 图标到标题的间距
    static let iconToTitle: CGFloat = 0
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
    static let iconContainerSize: CGFloat = 80
    /// 图标尺寸
    static let iconSize: CGFloat = 48
  }
}

// MARK: - Add Schedule Content
private struct AddScheduleContent: View {
  @ObservedObject var viewModel: AddScheduleViewModel
  @Environment(\.colorScheme) private var colorScheme
  @State private var isTitleHovered = false

  var body: some View {
    VStack(spacing: 0) {
      // 日历图标 - 直接集成了原来的CalendarIcon和BaseIconView
      ZStack(alignment: .center) {
        Image(systemName: "calendar.badge.plus")
          .font(.system(size: Design.Size.iconSize, weight: viewModel.isPremium ? .medium : .regular))
          .foregroundStyle(
            LinearGradient(
              colors: [
                DesignSystem.Colors.primary,
                DesignSystem.Colors.primary,
              ],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
          )
          .symbolEffect(.bounce, value: viewModel.isPremium)
          .modifier(DragAnimationModifier(animation: viewModel.dragAnimation))
      }
      .frame(width: Design.Size.iconContainerSize, height: Design.Size.iconContainerSize)
      .zIndex(Double(viewModel.isDragging ? ZIndex.dragElevated : ZIndex.content))

      // 标题 - 直接集成了原来的TitleSection和AppTitleView
      Text(AppInfo.name)
        .font(.system(size: 32, weight: .bold, design: .rounded))
        .foregroundStyle(
          LinearGradient(
            colors: [
              DesignSystem.Colors.primary,
              DesignSystem.Colors.primary.opacity(0.8),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
        .shadow(
          color: colorScheme == .dark ? DesignSystem.Colors.primary.opacity(0.3) : .clear,
          radius: isTitleHovered ? 15 : 10
        )
        .scaleEffect(isTitleHovered ? 1.05 : 1.0)
        .padding(.top, 4)
        .padding(.bottom, Design.Spacing.titleToActions)
        .padding(.horizontal)
        .contentShape(Rectangle())

      Spacer(minLength: 0)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

// MARK: - Manual Input Sheet
private struct ManualInputSheet: View {
  @ObservedObject var viewModel: AddScheduleViewModel

  var body: some View {
    ManualScheduleInputView(
      isPresented: $viewModel.showManualInputSheet,
      processInput: viewModel.processManualInput,
      viewModel: viewModel,
      onEventsProcessed: { events in
        viewModel.parsedEvents = events
        viewModel.showEventList = true
      }
    )
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

  private var buttonText: LocalizedStringKey {
    viewModel.isPremium ? "subscribed_status" : "upgrade_to_premium"
  }

  var body: some View {
    Button(action: {
      viewModel.showPaywallView()
    }) {
      HStack(spacing: 4) {
        Image(systemName: "sparkles")
          .foregroundColor(.yellow)
        Text(buttonText)
          .font(DesignSystem.Typography.caption)
          .foregroundColor(viewModel.isPremium ? .green : DesignSystem.Colors.primary)
      }
      .padding(.vertical, 6)
      .padding(.horizontal, 12)
    }
    .buttonStyle(.plain)
    .withHoverEffect(scale: 1.1, brightness: 0)
    .help(NSLocalizedString(viewModel.isPremium ? "subscribed_hint" : "upgrade_button_hint", comment: ""))
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
      HelpButtonLabel(isHovered: isHovered, isPressed: isPressed)
    }
    .buttonStyle(.plain)
    .onHover { hovering in
      withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
        isHovered = hovering
      }
    }
    .pressEvents(
      onPress: {
        withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
          isPressed = true
        }
      },
      onRelease: {
        withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
          isPressed = false
        }
      }
    )
    .zIndex(Double(ZIndex.topLayer))  // 确保帮助按钮始终可点击
  }
}

// MARK: - Help Button Label
private struct HelpButtonLabel: View {
  let isHovered: Bool
  let isPressed: Bool
  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    Image(systemName: "questionmark.circle.fill")
      .font(.system(size: 20))
      .foregroundStyle(
        LinearGradient(
          colors: [
            DesignSystem.Colors.primary,
            DesignSystem.Colors.primary.opacity(0.8),
          ],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
      )
      .background(
        Circle()
          .fill(colorScheme == .dark ? Color.black.opacity(0.3) : Color.white.opacity(0.8))
          .shadow(
            color: colorScheme == .dark
              ? DesignSystem.Colors.primary.opacity(isHovered ? 0.4 : 0.3)
              : DesignSystem.Colors.primary.opacity(isHovered ? 0.3 : 0.2),
            radius: isHovered ? 8 : 6,
            x: 0,
            y: colorScheme == .dark ? 1 : 2
          )
      )
      .scaleEffect(isPressed ? 0.95 : (isHovered ? 1.05 : 1.0))
      .padding(.vertical, 8)
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

// MARK: - View Extension
extension View {
  @ViewBuilder
  fileprivate func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
    if condition {
      transform(self)
    } else {
      self
    }
  }
}

// MARK: - Helper Functions
private func getManualInputIcon() -> String {
  if #available(macOS 14.0, *) {
    return "doc.plaintext.fill"
  } else {
    return "text.page.fill"
  }
}

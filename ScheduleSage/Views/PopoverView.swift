import AppKit
import SwiftUI

// 日程添加页
struct PopoverView: View {
  @EnvironmentObject private var viewModel: PopoverViewModel
  @State private var remainingUses: Int = 12

  var body: some View {
    VStack(spacing: 0) {
      mainContent
        .withLoading()
    }
  }

  private var mainContent: some View {
    ZStack {
      if viewModel.showEventList {
        EventListView(
          proStatus: viewModel.proStatus,
          events: PreviewData.events,
          onUpgrade: { viewModel.showUpgradeSheetAction() },
          onAdd: { viewModel.resetState() },
          onImport: { print("Import tapped") },
          onBack: { viewModel.showEventList = false }
        )
        .transition(
          .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
          )
        )
      } else {
        addScheduleView
          .transition(
            .asymmetric(
              insertion: .move(edge: .leading).combined(with: .opacity),
              removal: .move(edge: .trailing).combined(with: .opacity)
            )
          )
      }
    }
    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.showEventList)
    .onAppear {
      viewModel.resetState()
    }
  }

  private var addScheduleView: some View {
    VStack(spacing: 0) {
      // 顶部状态栏
      HStack {
        statusBar
        Spacer()
        SettingsButton()
          .foregroundColor(ScheduleDesignSystem.Colors.secondaryGray)
          .frame(width: 44, height: 44)
      }
      .frame(height: ScheduleDesignSystem.Dimensions.headerHeight)
      .background(ScheduleDesignSystem.Colors.background)
      .cornerRadius(ScheduleDesignSystem.Dimensions.headerCornerRadius)

      // 主要内容区域
      DragDropArea(
        isDragging: $viewModel.isDragging,
        isOCRProcessing: $viewModel.isOCRProcessing,
        onDrop: { urls in
          viewModel.handleDropped(urls)
        },
        onDragEntered: {
          viewModel.handleDragEntered()
        },
        onDragExited: {
          viewModel.handleDragExited()
        }
      ) {
        VStack(spacing: ScheduleDesignSystem.Spacing.vertical) {
          Spacer()
            .frame(height: ScheduleDesignSystem.Spacing.vertical)

          // 日历图标
          calendarIcon
            .modifier(DragAnimationModifier(animation: viewModel.dragAnimation))

          // 更新后的标题部分
          titleSection

          // 三种添加方式
          addMethodButtons

          Spacer()

          // 导入按钮
          importButton
        }
        .frame(maxWidth: .infinity)
      }
    }
    .frame(
      width: ScheduleDesignSystem.Dimensions.containerWidth,
      height: ScheduleDesignSystem.Dimensions.containerHeight
    )
    .background(ScheduleDesignSystem.Colors.background)
    .cornerRadius(ScheduleDesignSystem.Dimensions.containerCornerRadius)
  }

  private var statusBar: some View {
    HStack(spacing: ScheduleDesignSystem.Spacing.elementSpacing) {
      ProStatusView(
        status: viewModel.proStatus,  // 从 ViewModel 获取状态
        onUpgrade: { viewModel.showUpgradeSheetAction() },
        style: .compact
      )

      Spacer()
    }
    .padding(.horizontal, ScheduleDesignSystem.Layout.statusBarPadding.leading)
    .padding(.top, ScheduleDesignSystem.Layout.statusBarPadding.top)
    .padding(.bottom, ScheduleDesignSystem.Layout.statusBarPadding.bottom)
  }

  private var calendarIcon: some View {
    ZStack {
      Circle()
        .fill(ScheduleDesignSystem.Colors.lightGray)
        .frame(
          width: ScheduleDesignSystem.Dimensions.emptyStateIconSize,
          height: ScheduleDesignSystem.Dimensions.emptyStateIconSize
        )
      Image(systemName: "calendar.badge.plus")  // 使用更合适的日历图标
        .font(.system(size: 32))
        .foregroundColor(ScheduleDesignSystem.Colors.iconGray)
    }
  }

  private var addMethodButtons: some View {
    HStack(spacing: ScheduleDesignSystem.Spacing.horizontal) {
      AddMethodButton(
        icon: "doc.text.fill",
        text: NSLocalizedString("clipboard_import", comment: "")
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
              print("🔵 Image selected: \(url.path)")
            },
            onError: { error in
              print("🔴 Image selection failed: \(error.localizedDescription)")
            }
          ).showPicker()
        }
      )
    }
    .padding(.horizontal, ScheduleDesignSystem.Layout.containerPadding.leading)
    .padding(.top, ScheduleDesignSystem.Spacing.vertical * 1.2)
  }

  private func handleImageDrop(_ images: [NSImage]) {
    guard let image = images.first else { return }
    print("Processing dropped image: \(image.size)")
  }

  // MARK: - Private Views
  private var addButton: some View {
    Button(action: {
      print("Add button tapped")
    }) {
      Image(systemName: "plus")
        .foregroundColor(ScheduleDesignSystem.Colors.background)
        .frame(
          width: ScheduleDesignSystem.Dimensions.addButtonSize,
          height: ScheduleDesignSystem.Dimensions.addButtonSize
        )
        .background(ScheduleDesignSystem.Colors.primary)
        .clipShape(Circle())
    }
    .buttonStyle(.plain)
    .padding(.trailing, ScheduleDesignSystem.Spacing.headerHorizontalPadding)
  }

  private var importButton: some View {
    Button(action: {
      viewModel.showEventList = true
    }) {
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

  private var upgradeButton: some View {
    Button(action: { print("Upgrade tapped") }) {
      HStack(spacing: 4) {
        Image(systemName: "star.fill")
          .font(.system(size: 12))
        Text("升级 Pro")
          .font(ScheduleDesignSystem.Typography.statusText)
      }
      .foregroundColor(ScheduleDesignSystem.Colors.primary)
    }
    .buttonStyle(.plain)
    .withHoverEffect(brightness: 0.1)
  }

  private var titleSection: some View {
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

// 拖拽动画修饰器
struct DragAnimationModifier: ViewModifier {
  let animation: PopoverViewModel.DragAnimation

  func body(content: Content) -> some View {
    switch animation {
    case .none:
      content
    case .pulse:
      content
        .scaleEffect(1.1)
        .animation(animation.animation, value: animation)
    case .bounce:
      content
        .offset(y: -10)
        .animation(animation.animation, value: animation)
    case .glow:
      content
        .shadow(color: ScheduleDesignSystem.Colors.primary.opacity(0.5), radius: 20)
        .animation(animation.animation, value: animation)
    case .scale:
      content
        .scaleEffect(1.2)
        .animation(animation.animation, value: animation)
    }
  }
}

import AppKit
import SwiftUI

// 日程添加页
struct PopoverView: View {
  @EnvironmentObject private var viewModel: PopoverViewModel
  @State private var remainingUses: Int = 12

  var body: some View {
    mainContent
      .withLoading()
  }

  private var mainContent: some View {
    ZStack {
      if viewModel.showEventList {
        EventListView(
          remainingUses: remainingUses,
          events: PreviewData.events,
          onUpgrade: { print("Upgrade tapped") },
          onAdd: { viewModel.resetState() },
          onImport: { print("Import tapped") }
        )
        .transition(.asymmetric(
          insertion: .move(edge: .trailing).combined(with: .opacity),
          removal: .move(edge: .leading).combined(with: .opacity)
        ))
      } else {
        addScheduleView
          .transition(.asymmetric(
            insertion: .move(edge: .leading).combined(with: .opacity),
            removal: .move(edge: .trailing).combined(with: .opacity)
          ))
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
        closeButton
      }
      .frame(height: ScheduleDesignSystem.Dimensions.headerHeight)
      .background(ScheduleDesignSystem.Colors.background)
      .cornerRadius(ScheduleDesignSystem.Dimensions.headerCornerRadius)
      
      // 主要内容区域
      VStack(spacing: ScheduleDesignSystem.Spacing.vertical) {
        Spacer()
          .frame(height: ScheduleDesignSystem.Spacing.vertical * 2)
        
        // 日历图标
        calendarIcon
          .modifier(DragAnimationModifier(animation: viewModel.dragAnimation))
        
        Text(NSLocalizedString("add_schedule_title", comment: ""))
          .font(ScheduleDesignSystem.Typography.emptyStateTitle)
          .foregroundColor(ScheduleDesignSystem.Colors.primaryText)
          .padding(.top, ScheduleDesignSystem.Spacing.vertical)
        
        // 三种添加方式
        addMethodButtons
        
        Spacer()
        
        // 导入按钮
        importButton
      }
      .frame(maxWidth: .infinity)
      .background(
        ScheduleDesignSystem.Colors.containerGray
          .onDrop(
            of: [.fileURL],
            delegate: ImageDropDelegate(
              onDrop: { [weak viewModel] urls in
                print("🔵 View - onDrop callback with \(urls.count) URLs")
                viewModel?.handleDropped(urls)
              },
              onEntered: { [weak viewModel] in
                print("🔵 View - onEntered callback")
                viewModel?.handleDragEntered()
              },
              onExited: { [weak viewModel] in
                print("🔵 View - onExited callback")
                viewModel?.handleDragExited()
              },
              onOCRStateChange: { [weak viewModel] isProcessing in
                viewModel?.isOCRProcessing = isProcessing
              }
            )
          )
      )
    }
    .frame(
      width: ScheduleDesignSystem.Dimensions.containerWidth,
      height: ScheduleDesignSystem.Dimensions.containerHeight
    )
    .background(ScheduleDesignSystem.Colors.background)
    .cornerRadius(ScheduleDesignSystem.Dimensions.containerCornerRadius)
  }

  private var statusBar: some View {
    HStack {
      // Pro 状态栏内容
      proStatus
      Spacer()
      addButton
    }
    .frame(height: ScheduleDesignSystem.Dimensions.headerHeight)
    .background(ScheduleDesignSystem.Colors.background)
    .cornerRadius(ScheduleDesignSystem.Dimensions.headerCornerRadius)
  }

  private var proStatus: some View {
    HStack(spacing: ScheduleDesignSystem.Spacing.elementSpacing) {
      ZStack {
        Circle()
          .fill(ScheduleDesignSystem.Colors.lightGray)
          .frame(
            width: ScheduleDesignSystem.Dimensions.crownIconSize,
            height: ScheduleDesignSystem.Dimensions.crownIconSize
          )
        Image(systemName: "crown.fill")  // 使用 crown.fill 更接近视觉稿
          .foregroundColor(ScheduleDesignSystem.Colors.secondaryGray)
      }
      Text(String(format: NSLocalizedString("remaining_uses", comment: ""), remainingUses))
        .font(ScheduleDesignSystem.Typography.statusText)
        .foregroundColor(ScheduleDesignSystem.Colors.secondaryText)
      Text(NSLocalizedString("separator", comment: ""))
        .font(ScheduleDesignSystem.Typography.statusText)
        .foregroundColor(ScheduleDesignSystem.Colors.secondaryText)
      Text(NSLocalizedString("upgrade_prompt", comment: ""))
        .font(ScheduleDesignSystem.Typography.statusText)
        .foregroundColor(ScheduleDesignSystem.Colors.primary)
    }
    .padding(.leading, ScheduleDesignSystem.Spacing.headerHorizontalPadding)
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
        icon: "doc.text.fill",  // 更新图标
        text: NSLocalizedString("clipboard_import", comment: "")
      )
      AddMethodButton(
        icon: "square.and.pencil",  // 更新图标
        text: NSLocalizedString("manual_input", comment: "")
      )
      AddMethodButton(
        icon: "arrow.down.doc.fill",  // 更新图标
        text: NSLocalizedString("drag_image", comment: "")
      )
    }
    .padding(.horizontal, ScheduleDesignSystem.Spacing.horizontal)
    .padding(.top, ScheduleDesignSystem.Spacing.vertical)
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
        .background(ScheduleDesignSystem.Colors.primary.opacity(0.5))
        .cornerRadius(ScheduleDesignSystem.Dimensions.buttonCornerRadius)
    }
    .buttonStyle(.plain)
    .padding(ScheduleDesignSystem.Layout.containerPadding)
  }

  private var closeButton: some View {
    Button(action: {
      NSApplication.shared.keyWindow?.close()
    }) {
      Image(systemName: "xmark")
        .foregroundColor(ScheduleDesignSystem.Colors.background)
        .frame(
          width: ScheduleDesignSystem.Dimensions.addButtonSize,
          height: ScheduleDesignSystem.Dimensions.addButtonSize
        )
        .background(ScheduleDesignSystem.Colors.secondaryGray)
        .clipShape(Circle())
    }
    .buttonStyle(.plain)
    .padding(.trailing, ScheduleDesignSystem.Spacing.headerHorizontalPadding)
  }
}

struct AddMethodButton: View {
  let icon: String
  let text: String

  var body: some View {
    VStack {
      ZStack {
        Circle()
          .fill(ScheduleDesignSystem.Colors.lightGray)
          .frame(
            width: ScheduleDesignSystem.Dimensions.methodIconSize,
            height: ScheduleDesignSystem.Dimensions.methodIconSize
          )
        Image(systemName: icon)
          .foregroundColor(ScheduleDesignSystem.Colors.iconGray)
      }
      Text(text)
        .font(ScheduleDesignSystem.Typography.methodLabel)
        .foregroundColor(ScheduleDesignSystem.Colors.secondaryText)
    }
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

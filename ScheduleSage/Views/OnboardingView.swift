//
//  OnboardingView.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-21.
//

import SwiftUI

private struct OnboardingCompletionKey: EnvironmentKey {
  static let defaultValue: () -> Void = {}
}

extension EnvironmentValues {
  var onboardingCompletion: () -> Void {
    get { self[OnboardingCompletionKey.self] }
    set { self[OnboardingCompletionKey.self] = newValue }
  }
}

/// NSPageController 的 SwiftUI 包装器
private struct PageControllerView: NSViewControllerRepresentable {
  @Binding var currentPage: Int
  let pages: [OnboardingPage]
  let viewModel: OnboardingViewModel

  @MainActor
  func makeNSViewController(context: Context) -> NSPageController {
    let controller = NSPageController()
    controller.delegate = context.coordinator
    controller.transitionStyle = .horizontalStrip

    // 配置转场动画
    let transition = CATransition()
    transition.type = .push
    transition.subtype = .fromRight
    transition.duration = 0.3
    transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
    controller.view.layer?.actions = ["sublayers": transition]

    // 配置视图控制器
    controller.view.wantsLayer = true
    controller.view.layerContentsRedrawPolicy = .onSetNeedsDisplay

    // 设置内容大小
    controller.view.frame.size = NSSize(
      width: DesignSystem.Dimensions.mainViewWidth,
      height: DesignSystem.Dimensions.mainViewHeight
    )

    // 延迟设置 arrangedObjects 以确保视图层级准备就绪
    DispatchQueue.main.async {
      controller.arrangedObjects = pages
      controller.selectedIndex = currentPage
    }

    return controller
  }

  @MainActor
  func updateNSViewController(_ pageController: NSPageController, context: Context) {
    if pageController.selectedIndex != currentPage {
      // 使用异步更新避免布局递归
      DispatchQueue.main.async {
        pageController.animator().selectedIndex = currentPage
      }
    }
  }

  @MainActor
  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }

  class Coordinator: NSObject, NSPageControllerDelegate {
    var parent: PageControllerView

    init(_ pageController: PageControllerView) {
      self.parent = pageController
    }

    func pageController(
      _ pageController: NSPageController,
      viewControllerForIdentifier identifier: String
    ) -> NSViewController {
      let hostingController = NSHostingController(
        rootView: OnboardingPageView(
          page: parent.pages[Int(identifier) ?? 0],
          viewModel: parent.viewModel
        )
      )

      // 配置视图
      let view = hostingController.view
      view.wantsLayer = true
      view.layerContentsRedrawPolicy = .onSetNeedsDisplay

      // 使用 frame-based 布局而不是自动布局
      view.translatesAutoresizingMaskIntoConstraints = true
      view.frame = pageController.view.bounds
      view.autoresizingMask = [.width, .height]

      return hostingController
    }

    func pageController(_ pageController: NSPageController, identifierFor object: Any) -> String {
      if let index = parent.pages.firstIndex(where: { $0.id == (object as? OnboardingPage)?.id }) {
        return String(index)
      }
      return "0"
    }

    func pageControllerDidEndLiveTransition(_ pageController: NSPageController) {
      pageController.completeTransition()
      // 使用异步更新避免布局递归
      DispatchQueue.main.async {
        self.parent.currentPage = pageController.selectedIndex
      }
    }

    func pageController(_ pageController: NSPageController, prepare viewController: NSViewController, with object: Any?)
    {
      guard let page = object as? OnboardingPage,
        let hostingController = viewController as? NSHostingController<OnboardingPageView>
      else {
        return
      }

      // 更新 frame 以匹配父视图
      hostingController.view.frame = pageController.view.bounds

      // 使用异步更新避免布局递归
      DispatchQueue.main.async {
        hostingController.rootView = OnboardingPageView(
          page: page,
          viewModel: self.parent.viewModel
        )
      }
    }
  }
}

/// OnboardingView
/// Onboarding 引导页面
/// 展示 App 功能介绍和权限请求
struct OnboardingView: View {
  @StateObject private var viewModel = OnboardingViewModel()
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.onboardingCompletion) private var onboardingCompletion
  @State private var isFinishHovered = false
  @State private var isNextHovered = false
  @State private var isBackHovered = false

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        // 简化背景，删除渐变，使用带透明度的背景色
        Color(
          colorScheme == .dark ? NSColor.black.withAlphaComponent(0.2) : NSColor.systemBlue.withAlphaComponent(0.08)
        )
        .ignoresSafeArea(.all)
        .frame(maxWidth: .infinity, maxHeight: .infinity)

        // 磨砂玻璃效果层
        if #available(macOS 12.0, *) {
          Rectangle()
            .fill(Material.regularMaterial)
            .opacity(colorScheme == .dark ? 0.9 : 0.85)
            .ignoresSafeArea(.all)
        } else {
          Rectangle()
            .fill(colorScheme == .dark ? DesignSystem.Colors.background.opacity(0.8) : Color.white.opacity(0.7))
            .ignoresSafeArea(.all)

          // 保留顶部轻微高光效果，增强立体感
          Rectangle()
            .fill(
              LinearGradient(
                colors: [
                  Color.white.opacity(colorScheme == .dark ? 0.06 : 0.2),
                  Color.clear,
                ],
                startPoint: .top,
                endPoint: .center
              )
            )
            .ignoresSafeArea(.all)
        }

        VStack(spacing: 0) {
          // 页面内容
          PageControllerView(
            currentPage: $viewModel.currentPageIndex,
            pages: viewModel.pages,
            viewModel: viewModel
          )
          .frame(maxWidth: .infinity, maxHeight: .infinity)

          // 底部控制栏 - 添加磨砂效果
          if #available(macOS 12.0, *) {
            bottomControlBar
              .padding(.vertical, 12)
              .background(
                ZStack {
                  // 使用轻微的玻璃效果让底部控制栏与内容区分
                  Rectangle()
                    .fill(Material.ultraThinMaterial)
                    .opacity(0.6)

                  // 顶部添加微妙的分隔线
                  VStack {
                    Rectangle()
                      .fill(
                        LinearGradient(
                          colors: [
                            DesignSystem.Colors.primary.opacity(0.1),
                            DesignSystem.Colors.primary.opacity(0.02),
                          ],
                          startPoint: .top,
                          endPoint: .bottom
                        )
                      )
                      .frame(height: 1)
                    Spacer()
                  }
                }
              )
          } else {
            bottomControlBar
          }
        }
        .padding(.vertical, DesignSystem.Spacing.vertical)
      }
      .frame(width: geometry.size.width, height: geometry.size.height)
    }
    .frame(
      width: DesignSystem.Dimensions.mainViewWidth,
      height: DesignSystem.Dimensions.mainViewHeight
    )
  }

  // MARK: - Subviews

  private var bottomControlBar: some View {
    HStack {
      // 返回按钮
      if viewModel.canGoBack {
        Button(action: { viewModel.goToPreviousPage() }) {
          Label(
            NSLocalizedString("onboarding.button.back", comment: ""),
            systemImage: "chevron.left"
          )
          .font(DesignSystem.Typography.bodyMedium)
          .foregroundColor(DesignSystem.Colors.primary.opacity(isBackHovered ? 0.8 : 1.0))
        }
        .buttonStyle(.plain)
        .scaleEffect(isBackHovered ? 1.02 : 1.0)
        .onHover { hovering in
          withAnimation(.easeInOut(duration: 0.2)) {
            isBackHovered = hovering
          }
        }
      }

      Spacer()

      // 页面指示器
      PageIndicator(
        numberOfPages: viewModel.pages.count,
        currentPage: viewModel.currentPageIndex
      )

      Spacer()

      // 下一步/完成按钮
      if viewModel.isLastPage {
        Button(action: {
          viewModel.finish()
          onboardingCompletion()
        }) {
          Text("onboarding.button.finish")
            .font(DesignSystem.Typography.buttonLabel)
            .padding(.horizontal, 2)
            .padding(.vertical, 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.borderedProminent)
        .tint(DesignSystem.Colors.primary)
        .scaleEffect(isFinishHovered ? 1.02 : 1.0)
        .brightness(isFinishHovered ? -0.05 : 0)
        .shadow(
          color: DesignSystem.Colors.primary.opacity(isFinishHovered ? 0.4 : 0.3),
          radius: isFinishHovered ? 6 : 4,
          x: 0,
          y: isFinishHovered ? 3 : 2
        )
        .onHover { hovering in
          withAnimation(.easeInOut(duration: 0.2)) {
            isFinishHovered = hovering
          }
        }
      } else {
        Button(action: { viewModel.goToNextPage() }) {
          Label(
            NSLocalizedString("onboarding.button.next", comment: ""),
            systemImage: "chevron.right"
          )
          .font(DesignSystem.Typography.bodyMedium)
          .foregroundColor(DesignSystem.Colors.primary.opacity(isNextHovered ? 0.8 : 1.0))
        }
        .buttonStyle(.plain)
        .scaleEffect(isNextHovered ? 1.02 : 1.0)
        .onHover { hovering in
          withAnimation(.easeInOut(duration: 0.2)) {
            isNextHovered = hovering
          }
        }
      }
    }
    .padding(.horizontal, DesignSystem.Spacing.horizontal)
    .padding(.top, DesignSystem.Spacing.sectionSpacing)
    .background(DesignSystem.Colors.background.opacity(0.8))
  }
}

// MARK: - Helper Views

/// 页面指示器
private struct PageIndicator: View {
  let numberOfPages: Int
  let currentPage: Int

  var body: some View {
    HStack(spacing: DesignSystem.Spacing.iconSpacing) {
      ForEach(0..<numberOfPages, id: \.self) { index in
        Circle()
          .fill(
            index == currentPage
              ? DesignSystem.Colors.primary
              : DesignSystem.Colors.secondaryGray
          )
          .frame(
            width: index == currentPage
              ? DesignSystem.Dimensions.selectionIndicatorMiddleSize
              : DesignSystem.Dimensions.selectionIndicatorInnerSize,
            height: index == currentPage
              ? DesignSystem.Dimensions.selectionIndicatorMiddleSize
              : DesignSystem.Dimensions.selectionIndicatorInnerSize
          )
          .animation(.spring(), value: currentPage)
      }
    }
  }
}

// MARK: - Preview

#Preview {
  OnboardingView()
}

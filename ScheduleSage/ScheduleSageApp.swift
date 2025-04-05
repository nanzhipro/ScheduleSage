//
//  ScheduleSageApp.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-20.
//

import SwiftUI

@main
struct ScheduleSageApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  @StateObject private var viewModel = AddScheduleViewModel()
  @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
  @StateObject private var authViewModel = AuthenticationViewModel.shared
  @Environment(\.colorScheme) private var colorScheme

  // 窗口初始化后的配置 - 添加毛玻璃效果
  func configureWindow(_ window: NSWindow?) {
    guard let window = window else { return }

    // 配置窗口基本属性
    window.styleMask.remove([.resizable, .fullScreen])
    window.collectionBehavior.remove([.fullScreenPrimary, .fullScreenAuxiliary])

    // 设置窗口外观 - 简单透明背景
    window.titlebarAppearsTransparent = true
    window.titleVisibility = .hidden
    window.backgroundColor = .clear
    window.isOpaque = false  // 确保窗口不是不透明的
    window.hasShadow = true  // 添加窗口阴影
    window.contentView?.wantsLayer = true

    // 应用毛玻璃效果 - 使用NSVisualEffectView
    if let contentView = window.contentView {
      // 移除已有的毛玻璃视图（如果存在）
      contentView.subviews.forEach { subview in
        if subview is NSVisualEffectView {
          subview.removeFromSuperview()
        }
      }

      // 创建新的毛玻璃效果视图
      let visualEffectView = NSVisualEffectView()
      visualEffectView.material = .fullScreenUI  // 适合全窗口的毛玻璃效果
      visualEffectView.blendingMode = .behindWindow
      visualEffectView.state = .active
      visualEffectView.frame = contentView.bounds
      visualEffectView.autoresizingMask = [.width, .height]

      // 插入毛玻璃效果视图到最底层，确保内容视图在其上方
      contentView.addSubview(visualEffectView, positioned: .below, relativeTo: nil)
    }

    // 禁用标签栏
    window.tabbingMode = .disallowed

    // 确保窗口居中显示
    window.center()
  }

  var body: some Scene {
    WindowGroup {
      Group {
        if hasCompletedOnboarding {
          ZStack {
            // 1. 最底层：毛玻璃背景（来自WindowBlurBackground）
            // WindowBlurBackground()

            // // 2. 中间层：Messenger风格的背景渐变
            // WindowBackgroundView()
            //   .opacity(0.1)  // 降低不透明度以更好地显示底层毛玻璃效果

            // 3. 顶层：主内容视图 - 确保在毛玻璃效果之上
            AddScheduleView()
              .environmentObject(viewModel)
              .environmentObject(authViewModel)
              .frame(
                width: DesignSystem.Dimensions.mainViewWidth,
                height: DesignSystem.Dimensions.mainViewHeight
              )
              .zIndex(20)  // 确保内容视图始终在最上层
              .onAppear {
                // 配置窗口半透明效果
                configureWindow(NSApp.mainWindow)
              }
          }
        } else {
          // 引导页面，使用相同的层级结构
          ZStack {
            // 1. 最底层：毛玻璃背景
            // WindowBlurBackground()

            // 2. 中间层：Messenger风格的背景渐变
            // WindowBackgroundView()
            //   .opacity(0.1)  // 降低不透明度以更好地显示底层毛玻璃效果

            // 3. 顶层：引导页内容
            OnboardingView()
              .frame(
                width: DesignSystem.Dimensions.mainViewWidth,
                height: DesignSystem.Dimensions.mainViewHeight
              )
              .zIndex(20)  // 确保内容视图始终在最上层
              .environment(
                \.onboardingCompletion,
                {
                  hasCompletedOnboarding = true
                }
              )
              .onAppear {
                // 配置窗口半透明效果
                configureWindow(NSApp.mainWindow)
              }
          }
        }
      }
      // 不再需要额外的背景，因为已经在ZStack中添加了
    }
    // 窗口样式设置保持不变
    .windowStyle(.hiddenTitleBar)
    .windowResizability(.contentSize)
    .defaultPosition(.center)
    .commands {
      // 禁用新建窗口命令
      CommandGroup(replacing: .newItem) {}

      // 添加窗口菜单
      CommandGroup(replacing: .windowSize) {
        Button(NSLocalizedString("window.show_main_window", comment: "")) {
          appDelegate.showMainWindow()
        }
        .keyboardShortcut("1", modifiers: .command)

        Divider()

        Button(NSLocalizedString("window.minimize", comment: "")) {
          NSApp.mainWindow?.miniaturize(nil)
        }
        .keyboardShortcut("m", modifiers: .command)
      }
    }
    .onChange(of: ScenePhase.active) { _, _ in
      guard hasCompletedOnboarding else { return }
      configureWindow(NSApp.mainWindow)

      // 如果是自动外观模式，更新当前外观
      if let appearanceMode = UserDefaults.standard.string(forKey: "appearanceMode"),
        appearanceMode == AppearanceMode.auto.rawValue
      {
        if let isDark = NSApp.effectiveAppearance.isDarkMode {
          ThemeManager.shared.setDarkMode(isDark)
        }
      }
    }

    Settings {
      SettingsView()
        .environmentObject(authViewModel)
    }
  }
}

// 窗口毛玻璃背景 - 确保窗口整体有毛玻璃效果

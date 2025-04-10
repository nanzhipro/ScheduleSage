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

  var body: some Scene {
    // 主窗口
    Window("ScheduleSage", id: "main") {
      if hasCompletedOnboarding {
        MainNavigationView()
          .environmentObject(viewModel)
          .environmentObject(authViewModel)
          .frame(minHeight: DesignSystem.Dimensions.mainViewHeight)
          .onAppear {
            // 确保只创建一个主窗口
          }
      }
    }
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
      guard hasCompletedOnboarding,
        let window = NSApp.mainWindow
      else { return }

      // 设置窗口外观
      window.titlebarAppearsTransparent = true
      window.titleVisibility = .hidden
      window.backgroundColor = .clear
      window.contentView?.wantsLayer = true

      // 禁用标签栏
      window.tabbingMode = .disallowed

      // 确保窗口居中显示
      window.center()

      // 如果是自动外观模式，更新当前外观
      if let appearanceMode = UserDefaults.standard.string(forKey: "appearanceMode"),
        appearanceMode == AppearanceMode.auto.rawValue
      {
        if let isDark = NSApp.effectiveAppearance.isDarkMode {
          ThemeManager.shared.setDarkMode(isDark)
        }
      }
    }

    #if false
    // 菜单栏额外内容 - 当日全天事件视图
    MenuBarExtra(
      NSLocalizedString("today_all_day_events", comment: "Today's Most Important Tasks"),
      systemImage: "list.star"
    ) {
      MenuBarEventView()
    }
    .menuBarExtraStyle(.window)
    #endif

    Settings {
      SettingsView()
        .environmentObject(authViewModel)
    }
  }
}

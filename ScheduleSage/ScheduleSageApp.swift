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

  var body: some Scene {
    WindowGroup {
      Group {
        if hasCompletedOnboarding {
          AddScheduleView()
            .environmentObject(viewModel)
            .frame(
              width: DesignSystem.Dimensions.mainViewWidth,
              height: DesignSystem.Dimensions.mainViewHeight
            )
        }
      }
    }
    .windowStyle(.hiddenTitleBar)
    .windowResizability(.contentSize)
    .defaultPosition(.center)
    .commands {
      // 禁用新建窗口命令
      CommandGroup(replacing: .newItem) { }
    }
    .onChange(of: ScenePhase.active) { _, _ in
      guard hasCompletedOnboarding,
            let window = NSApp.mainWindow else { return }
      
      // 配置窗口基本属性
      window.styleMask.remove([.resizable, .miniaturizable, .fullScreen])
      window.collectionBehavior.remove([.fullScreenPrimary, .fullScreenAuxiliary])
      
      // 设置窗口外观
      window.titlebarAppearsTransparent = true
      window.titleVisibility = .hidden
      window.backgroundColor = .clear
      window.contentView?.wantsLayer = true
    }

    Settings {
      SettingsView()
    }
  }
}

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

  var body: some Scene {
    WindowGroup {
      AddScheduleView()
        .environmentObject(viewModel)
        .frame(
          width: DesignSystem.Dimensions.mainViewWidth,
          height: DesignSystem.Dimensions.mainViewHeight
        )
    }
    .windowStyle(.hiddenTitleBar)
    .windowResizability(.contentSize)
    .defaultPosition(.center)
    .onChange(of: ScenePhase.active) { _, _ in
      guard let window = NSApp.mainWindow else { return }
      
      // 配置窗口基本属性
      window.styleMask.remove([.resizable, .miniaturizable, .fullScreen])
      window.collectionBehavior.remove([.fullScreenPrimary, .fullScreenAuxiliary])
      
      // 设置窗口外观
      window.titlebarAppearsTransparent = true
      window.titleVisibility = .hidden
      window.backgroundColor = .clear
      window.contentView?.wantsLayer = true
      
      // 设置窗口层级
      window.level = .floating
    }

    Settings {
      SettingsView()
    }
  }
}

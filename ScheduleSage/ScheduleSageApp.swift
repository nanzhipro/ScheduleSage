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
        .ignoresSafeArea()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .windowStyle(.hiddenTitleBar)
    .windowResizability(.contentSize)
    .defaultSize(
      width: DesignSystem.Dimensions.mainViewWidth,
      height: DesignSystem.Dimensions.mainViewHeight
    )
    .defaultPosition(.center)
    .windowToolbarStyle(.unifiedCompact)
    .commands {
      CommandGroup(replacing: .windowSize) {
        Button("Enter Full Screen") {}.hidden()
      }
    }
    .onChange(of: ScenePhase.active) { oldValue, newValue in
      guard let window = NSApp.mainWindow else { return }
      window.styleMask.remove(.resizable)
      window.styleMask.remove(.miniaturizable)
      
      window.titlebarAppearsTransparent = true
      window.titleVisibility = .hidden
      
      if let contentView = window.contentView {
        contentView.wantsLayer = true
        window.backgroundColor = .clear
      }
    }

    Settings {
      SettingsView()
    }
  }
}

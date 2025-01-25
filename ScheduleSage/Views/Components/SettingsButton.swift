//
//  SettingsButton.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-20.
//

import SwiftUI
import AppKit

struct SettingsButton: View {
  private static var settingsWindow: NSWindow?
  
  var body: some View {
    Menu {
      settingsButton
      Divider()
      quitButton
    } label: {
      settingsIcon
    }
    .menuStyle(BorderlessButtonMenuStyle())
    .menuIndicator(.hidden)
    .frame(width: 44, height: 44)
  }
  
  private var settingsButton: some View {
    Button(action: openSettings) {
      Label(
        NSLocalizedString("settings_preferences", comment: ""),
        systemImage: "gear"
      )
    }
    .foregroundColor(ScheduleDesignSystem.Colors.primaryText)
  }
  
  private var quitButton: some View {
    Button(action: { NSApplication.shared.terminate(nil) }) {
      Label(
        NSLocalizedString("settings_quit", comment: ""),
        systemImage: "power"
      )
    }
    .foregroundColor(ScheduleDesignSystem.Colors.primaryText)
  }
  
  private var settingsIcon: some View {
    Image(systemName: "gear.badge.checkmark")
      .font(.system(size: ScheduleDesignSystem.Dimensions.settingsButtonSize))
      .foregroundColor(ScheduleDesignSystem.Colors.secondaryGray)
      .contentShape(Rectangle())
  }
  
  private func openSettings() {
    if let existingWindow = Self.settingsWindow {
      existingWindow.makeKeyAndOrderFront(nil)
      NSApp.activate(ignoringOtherApps: true)
      return
    }
    
    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 375, height: 520),
      styleMask: [.titled, .closable],
      backing: .buffered,
      defer: false
    )
    
    window.title = NSLocalizedString("settings_window_title", comment: "")
    window.center()
    window.level = .floating
    
    let hostingController = NSHostingController(
      rootView: SettingsView()
        .frame(width: 375, height: 520)
    )
    
    window.contentViewController = hostingController
    window.isReleasedWhenClosed = false
    window.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
    
    Self.settingsWindow = window
  }
}

#Preview {
  SettingsButton()
}

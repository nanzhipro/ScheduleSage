//
//  SettingsButton.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-20.
//

import SwiftUI
import AppKit

struct SettingsButton: View {
  @Environment(\.openSettings) private var openSettings
  
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
    Button(action: { openSettings() }) {
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
}

#Preview {
  SettingsButton()
}

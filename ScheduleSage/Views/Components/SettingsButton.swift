//
//  SettingsButton.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-20.
//

import SwiftUI
import AppKit

struct SettingsButton: View {
  var body: some View {
    Menu {
      SettingsLink {
        Label(
          NSLocalizedString("settings_preferences", comment: ""),
          systemImage: "gear"
        )
      }
      Divider()
      quitButton
    } label: {
      settingsIcon
    }
    .menuStyle(BorderlessButtonMenuStyle())
    .menuIndicator(.hidden)
    .frame(width: 44, height: 44)
  }
  
  private var quitButton: some View {
    Button(action: { NSApplication.shared.terminate(nil) }) {
      Label(
        NSLocalizedString("settings_quit", comment: ""),
        systemImage: "power"
      )
    }
    .foregroundColor(DesignSystem.Colors.primaryText)
  }
  
  private var settingsIcon: some View {
    Image(systemName: "gear.badge.checkmark")
      .font(.system(size: DesignSystem.Dimensions.settingsButtonSize))
      .foregroundColor(DesignSystem.Colors.secondaryGray)
      .contentShape(Rectangle())
  }
}

#Preview {
  SettingsButton()
}

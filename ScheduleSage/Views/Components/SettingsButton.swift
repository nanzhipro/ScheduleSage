//
//  SettingsButton.swift
//  ScheduleSage
//
//  Created by 南朋友 on 2024-03-20.
//

import SwiftUI

struct SettingsButton: View {
  @Environment(\.openSettings) private var openSettings

  var body: some View {
    Menu {
      Button(action: { openSettings() }) {
        Label(
          NSLocalizedString("settings_preferences", comment: ""),
          systemImage: "gear"
        )
        .foregroundColor(ScheduleDesignSystem.Colors.primaryText)
      }

      Divider()

      Button(action: quitApp) {
        Label(
          NSLocalizedString("settings_quit", comment: ""),
          systemImage: "power"
        )
        .foregroundColor(ScheduleDesignSystem.Colors.primaryText)
      }
    } label: {
      Image(systemName: "ellipsis.circle")
        .font(.system(size: ScheduleDesignSystem.Dimensions.settingsButtonSize))
        .foregroundColor(ScheduleDesignSystem.Colors.secondaryGray)
        .contentShape(Rectangle())
    }
    .menuStyle(BorderlessButtonMenuStyle())
    .menuIndicator(.hidden)
    .frame(width: 44, height: 44)
  }

  private func quitApp() {
    NSApplication.shared.terminate(nil)
  }
}

#Preview {
  SettingsButton()
}

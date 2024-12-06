//
//  SettingsButton.swift
//  ScheduleSage
//
//  Created by 南朋友 on 2024-03-20.
//

import SwiftUI

struct SettingsButton: View {
  var body: some View {
    Menu {
      Button(action: showPreferences) {
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
      Image(systemName: "ellipsis.circle.fill")
        .font(.system(size: ScheduleDesignSystem.Dimensions.settingsButtonSize))
        .foregroundColor(ScheduleDesignSystem.Colors.secondaryGray)
        .contentShape(Rectangle())
    }
    .menuStyle(BorderlessButtonMenuStyle())
    .menuIndicator(.hidden)
    .withHoverEffect(scale: 1.1)
    .frame(width: 44, height: 44)
  }

  private func showPreferences() {
    print("打开首选项设置")
    // TODO: 实现首选项页面
  }

  private func quitApp() {
    NSApplication.shared.terminate(nil)
  }
}

#Preview {
  SettingsButton()
}

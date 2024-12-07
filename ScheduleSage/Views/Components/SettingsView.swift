//
//  SettingsView.swift
//  ScheduleSage
//
//  Created by 南朋友 on 2024-03-20.
//

import SwiftUI

public struct SettingsView: View {
  @AppStorage("enableNotifications") private var enableNotifications = true
  @AppStorage("darkMode") private var darkMode = false
  @AppStorage("autoStart") private var autoStart = false
  @AppStorage("showPreviews") private var showPreviews = true
  @AppStorage("fontSize") private var fontSize: Double = 28

  public init() {}

  public var body: some View {
    TabView {
      generalSettings
        .tabItem {
          Label(
            NSLocalizedString("settings_tab_general", comment: ""),
            systemImage: "gearshape.fill"
          )
        }

      advancedSettings
        .tabItem {
          Label(
            NSLocalizedString("settings_tab_advanced", comment: ""),
            systemImage: "star.fill"
          )
        }
    }
    .frame(width: 375, height: 150)
  }

  private var generalSettings: some View {
    Form {
      Section {
        Toggle(NSLocalizedString("settings_notifications", comment: ""), isOn: $enableNotifications)
        Toggle(NSLocalizedString("settings_dark_mode", comment: ""), isOn: $darkMode)
        Toggle(NSLocalizedString("settings_auto_start", comment: ""), isOn: $autoStart)
      }

      Section {
        HStack {
          Text(NSLocalizedString("settings_version", comment: ""))
          Spacer()
          Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
            .foregroundColor(.secondary)
        }
      }
    }
    .formStyle(.grouped)
    .padding()
  }

  private var advancedSettings: some View {
    Form {
      Section {
        Toggle(NSLocalizedString("settings_show_previews", comment: ""), isOn: $showPreviews)

        VStack(alignment: .leading) {
          Text(NSLocalizedString("settings_font_size", comment: "") + " (\(Int(fontSize)) pts)")
          Slider(value: $fontSize, in: 12...48)
        }
      }
    }
    .formStyle(.grouped)
    .padding()
  }
}

#Preview {
  SettingsView()
}

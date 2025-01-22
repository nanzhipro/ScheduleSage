//
//  SettingsView.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-20.
//

import SwiftUI

public struct SettingsView: View {
  @AppStorage("enableNotifications") private var enableNotifications = true
  @AppStorage("darkMode") private var darkMode = false
  @AppStorage("autoStart") private var autoStart = false
  @AppStorage("showPreviews") private var showPreviews = true
  @AppStorage("fontSize") private var fontSize: Double = 28
  
  private let formPadding: CGFloat = 16
  private let frameSize = CGSize(width: 375, height: 250)
  
  public init() {}
  
  public var body: some View {
    TabView {
      generalSettings
        .tabItem {
          Label(
            NSLocalizedString("settings_tab_general", comment: ""),
            systemImage: "gearshape"
          )
        }
      
      advancedSettings
        .tabItem {
          Label(
            NSLocalizedString("settings_tab_advanced", comment: ""),
            systemImage: "star"
          )
        }
    }
    .frame(width: frameSize.width, height: frameSize.height)
  }
  
  private var generalSettings: some View {
    Form {
      notificationSection
      appearanceSection
      systemSection
      versionSection
    }
    .formStyle(.grouped)
    .padding(formPadding)
  }
  
  private var advancedSettings: some View {
    Form {
      previewSection
      fontSection
    }
    .formStyle(.grouped)
    .padding(formPadding)
  }
  
  private var notificationSection: some View {
    Section {
      Toggle(isOn: $enableNotifications) {
        Label {
          Text(NSLocalizedString("settings_notifications", comment: ""))
        } icon: {
          Image(systemName: "bell.badge")
            .foregroundStyle(Color.blue)
        }
      }
    } header: {
      Text(NSLocalizedString("settings_group_notifications", comment: ""))
    }
  }
  
  private var appearanceSection: some View {
    Section {
      Toggle(isOn: $darkMode) {
        Label {
          Text(NSLocalizedString("settings_dark_mode", comment: ""))
        } icon: {
          Image(systemName: "moon.fill")
            .foregroundStyle(Color.purple)
        }
      }
    } header: {
      Text(NSLocalizedString("settings_group_appearance", comment: ""))
    }
  }
  
  private var systemSection: some View {
    Section {
      Toggle(isOn: $autoStart) {
        Label {
          Text(NSLocalizedString("settings_auto_start", comment: ""))
        } icon: {
          Image(systemName: "power")
            .foregroundStyle(Color.green)
        }
      }
    } header: {
      Text(NSLocalizedString("settings_group_system", comment: ""))
    }
  }
  
  private var versionSection: some View {
    Section {
      HStack {
        Label {
          Text(NSLocalizedString("settings_version", comment: ""))
        } icon: {
          Image(systemName: "info.circle")
            .foregroundStyle(Color.gray)
        }
        Spacer()
        Text(Bundle.main.appVersion)
          .foregroundColor(.secondary)
      }
    } header: {
      Text(NSLocalizedString("settings_group_about", comment: ""))
    }
  }
  
  private var previewSection: some View {
    Section {
      Toggle(isOn: $showPreviews) {
        Label {
          Text(NSLocalizedString("settings_show_previews", comment: ""))
        } icon: {
          Image(systemName: "eye")
            .foregroundStyle(Color.orange)
        }
      }
    } header: {
      Text(NSLocalizedString("settings_group_preview", comment: ""))
    }
  }
  
  private var fontSection: some View {
    Section {
      VStack(alignment: .leading) {
        Label {
          Text(NSLocalizedString("settings_font_size", comment: "") + " (\(Int(fontSize)) pts)")
        } icon: {
          Image(systemName: "textformat.size")
            .foregroundStyle(Color.red)
        }
        Slider(value: $fontSize, in: 12...48)
          .padding(.leading, 28)
      }
    } header: {
      Text(NSLocalizedString("settings_group_font", comment: ""))
    }
  }
}

private extension Bundle {
  var appVersion: String {
    infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
  }
}

#Preview {
  SettingsView()
}

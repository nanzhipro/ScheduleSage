//
//  SettingsView.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-20.
//

import SwiftUI
import AppKit

struct SettingsView: View {
  @AppStorage("enableNotifications") private var enableNotifications = true {
    didSet {
      if enableNotifications {
        Task {
          await NotificationManager.shared.requestAuthorization()
        }
      }
    }
  }
  
  @StateObject private var themeManager = ThemeManager.shared
  @State private var showNotificationAlert = false
  @State private var autoStart: Bool = LaunchManager.shared.isLaunchAtStartupEnabled
  @State private var showLaunchError = false
  @AppStorage("useWindowMode") private var useWindowMode = true
  
  var body: some View {
    TabView {
      generalSettings
        .tabItem {
          Label(NSLocalizedString("settings_tab_general", comment: ""), systemImage: "gear")
        }
    }
    .frame(width: 375)
    .accentColor(DesignSystem.Colors.primary)
  }
  
  private var generalSettings: some View {
    Form {
      notificationSection
      appearanceSection
      systemSection
      versionSection
    }
    .formStyle(.grouped)
    .scrollContentBackground(.hidden)
    .background(DesignSystem.Colors.primaryBackground)
  }
  
  private var notificationSection: some View {
    Section {
      Toggle(isOn: Binding(
        get: { enableNotifications },
        set: { newValue in
          if newValue {
            Task {
              let isAuthorized = await NotificationManager.shared.checkNotificationStatus()
              if !isAuthorized {
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.notifications")!)
              }
              await MainActor.run {
                enableNotifications = isAuthorized
              }
            }
          } else {
            enableNotifications = false
          }
        }
      )) {
        Label {
          Text(NSLocalizedString("settings_notifications", comment: ""))
            .foregroundColor(DesignSystem.Colors.primaryText)
        } icon: {
          Image(systemName: "bell.badge")
            .foregroundStyle(DesignSystem.Colors.primary)
        }
      }
      .tint(DesignSystem.Colors.primary)
    } header: {
      Text(NSLocalizedString("settings_group_notifications", comment: ""))
        .foregroundColor(DesignSystem.Colors.secondaryText)
        .font(DesignSystem.Typography.formLabel)
    }
    .listRowBackground(DesignSystem.Colors.background)
  }
  
  private var appearanceSection: some View {
    Section {
      Toggle(isOn: Binding(
        get: { themeManager.isDarkModeEnabled },
        set: { themeManager.setDarkMode($0) }
      )) {
        Label {
          Text(NSLocalizedString("settings_dark_mode", comment: ""))
            .foregroundColor(DesignSystem.Colors.primaryText)
        } icon: {
          Image(systemName: "moon.fill")
            .foregroundStyle(DesignSystem.Colors.primary)
        }
      }
      .tint(DesignSystem.Colors.primary)
    } header: {
      Text(NSLocalizedString("settings_group_appearance", comment: ""))
        .foregroundColor(DesignSystem.Colors.secondaryText)
        .font(DesignSystem.Typography.formLabel)
    }
    .listRowBackground(DesignSystem.Colors.background)
  }
  
  private var systemSection: some View {
    Section {
      Toggle(isOn: Binding(
        get: { autoStart },
        set: { newValue in
          let success = LaunchManager.shared.setLaunchAtStartup(newValue)
          if success {
            autoStart = newValue
          } else {
            showLaunchError = true
            autoStart = LaunchManager.shared.isLaunchAtStartupEnabled
          }
        }
      )) {
        Label {
          Text(NSLocalizedString("settings_auto_start", comment: ""))
            .foregroundColor(DesignSystem.Colors.primaryText)
        } icon: {
          Image(systemName: "power")
            .foregroundStyle(DesignSystem.Colors.primary)
        }
      }
      .tint(DesignSystem.Colors.primary)
      
      Toggle(isOn: $useWindowMode) {
        Label {
          Text(NSLocalizedString("settings_window_mode", comment: ""))
            .foregroundColor(DesignSystem.Colors.primaryText)
        } icon: {
          Image(systemName: "macwindow")
            .foregroundStyle(DesignSystem.Colors.primary)
        }
      }
      .tint(DesignSystem.Colors.primary)
    } header: {
      Text(NSLocalizedString("settings_group_system", comment: ""))
        .foregroundColor(DesignSystem.Colors.secondaryText)
        .font(DesignSystem.Typography.formLabel)
    }
    .listRowBackground(DesignSystem.Colors.background)
    .alert(
      NSLocalizedString("settings_launch_error_title", comment: ""),
      isPresented: $showLaunchError,
      actions: {
        Button(NSLocalizedString("settings_ok", comment: ""), role: .cancel) {}
      },
      message: {
        Text(NSLocalizedString("settings_launch_error_message", comment: ""))
      }
    )
  }
  
  private var versionSection: some View {
    Section {
      HStack {
        Label {
          Text(NSLocalizedString("settings_version", comment: ""))
            .foregroundColor(DesignSystem.Colors.primaryText)
        } icon: {
          Image(systemName: "info.circle")
            .foregroundStyle(DesignSystem.Colors.primary)
        }
        Spacer()
        Text(Bundle.main.appVersion)
          .foregroundColor(DesignSystem.Colors.secondaryText)
          .font(DesignSystem.Typography.caption)
      }
    } header: {
      Text(NSLocalizedString("settings_group_about", comment: ""))
        .foregroundColor(DesignSystem.Colors.secondaryText)
        .font(DesignSystem.Typography.formLabel)
    }
    .listRowBackground(DesignSystem.Colors.background)
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

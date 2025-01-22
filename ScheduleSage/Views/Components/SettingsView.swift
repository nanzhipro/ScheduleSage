//
//  SettingsView.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-20.
//

import SwiftUI

public struct SettingsView: View {
  @AppStorage("enableNotifications") private var enableNotifications = true {
    didSet {
      if enableNotifications {
        NotificationManager.shared.requestAuthorization()
      }
    }
  }
  
  @StateObject private var themeManager = ThemeManager.shared
  @State private var showNotificationAlert = false
  @State private var autoStart: Bool = LaunchManager.shared.isLaunchAtStartupEnabled
  @State private var showLaunchError = false
  @AppStorage("showPreviews") private var showPreviews = true
  @AppStorage("fontSize") private var fontSize: Double = 28
  
  private let formPadding: CGFloat = ScheduleDesignSystem.Spacing.contentPadding
  private let frameSize = CGSize(width: 375, height: 520)
  
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
    .background(ScheduleDesignSystem.Colors.background)
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
    .background(ScheduleDesignSystem.Colors.primaryBackground)
  }
  
  private var advancedSettings: some View {
    Form {
      previewSection
      fontSection
    }
    .formStyle(.grouped)
    .padding(formPadding)
    .background(ScheduleDesignSystem.Colors.primaryBackground)
  }
  
  private var notificationSection: some View {
    Section {
      Toggle(isOn: Binding(
        get: { enableNotifications },
        set: { newValue in
          if newValue {
            NotificationManager.shared.checkNotificationStatus { isAuthorized in
              if !isAuthorized {
                NotificationManager.shared.openNotificationSettings()
              }
              enableNotifications = isAuthorized
            }
          } else {
            enableNotifications = false
          }
        }
      )) {
        Label {
          Text(NSLocalizedString("settings_notifications", comment: ""))
            .foregroundColor(ScheduleDesignSystem.Colors.primaryText)
        } icon: {
          Image(systemName: "bell.badge")
            .foregroundStyle(ScheduleDesignSystem.Colors.primary)
        }
      }
      .tint(ScheduleDesignSystem.Colors.primary)
    } header: {
      Text(NSLocalizedString("settings_group_notifications", comment: ""))
        .foregroundColor(ScheduleDesignSystem.Colors.secondaryText)
        .font(ScheduleDesignSystem.Typography.formLabel)
    }
    .listRowBackground(ScheduleDesignSystem.Colors.background)
  }
  
  private var appearanceSection: some View {
    Section {
      Toggle(isOn: Binding(
        get: { themeManager.isDarkModeEnabled },
        set: { themeManager.setDarkMode($0) }
      )) {
        Label {
          Text(NSLocalizedString("settings_dark_mode", comment: ""))
            .foregroundColor(ScheduleDesignSystem.Colors.primaryText)
        } icon: {
          Image(systemName: "moon.fill")
            .foregroundStyle(ScheduleDesignSystem.Colors.primary)
        }
      }
      .tint(ScheduleDesignSystem.Colors.primary)
    } header: {
      Text(NSLocalizedString("settings_group_appearance", comment: ""))
        .foregroundColor(ScheduleDesignSystem.Colors.secondaryText)
        .font(ScheduleDesignSystem.Typography.formLabel)
    }
    .listRowBackground(ScheduleDesignSystem.Colors.background)
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
            .foregroundColor(ScheduleDesignSystem.Colors.primaryText)
        } icon: {
          Image(systemName: "power")
            .foregroundStyle(ScheduleDesignSystem.Colors.primary)
        }
      }
      .tint(ScheduleDesignSystem.Colors.primary)
    } header: {
      Text(NSLocalizedString("settings_group_system", comment: ""))
        .foregroundColor(ScheduleDesignSystem.Colors.secondaryText)
        .font(ScheduleDesignSystem.Typography.formLabel)
    }
    .listRowBackground(ScheduleDesignSystem.Colors.background)
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
            .foregroundColor(ScheduleDesignSystem.Colors.primaryText)
        } icon: {
          Image(systemName: "info.circle")
            .foregroundStyle(ScheduleDesignSystem.Colors.primary)
        }
        Spacer()
        Text(Bundle.main.appVersion)
          .foregroundColor(ScheduleDesignSystem.Colors.secondaryText)
          .font(ScheduleDesignSystem.Typography.caption)
      }
    } header: {
      Text(NSLocalizedString("settings_group_about", comment: ""))
        .foregroundColor(ScheduleDesignSystem.Colors.secondaryText)
        .font(ScheduleDesignSystem.Typography.formLabel)
    }
    .listRowBackground(ScheduleDesignSystem.Colors.background)
  }
  
  private var previewSection: some View {
    Section {
      Toggle(isOn: $showPreviews) {
        Label {
          Text(NSLocalizedString("settings_show_previews", comment: ""))
            .foregroundColor(ScheduleDesignSystem.Colors.primaryText)
        } icon: {
          Image(systemName: "eye")
            .foregroundStyle(ScheduleDesignSystem.Colors.primary)
        }
      }
      .tint(ScheduleDesignSystem.Colors.primary)
    } header: {
      Text(NSLocalizedString("settings_group_preview", comment: ""))
        .foregroundColor(ScheduleDesignSystem.Colors.secondaryText)
        .font(ScheduleDesignSystem.Typography.formLabel)
    }
    .listRowBackground(ScheduleDesignSystem.Colors.background)
  }
  
  private var fontSection: some View {
    Section {
      VStack(alignment: .leading) {
        Label {
          Text(NSLocalizedString("settings_font_size", comment: "") + " (\(Int(fontSize)) pts)")
            .foregroundColor(ScheduleDesignSystem.Colors.primaryText)
        } icon: {
          Image(systemName: "textformat.size")
            .foregroundStyle(ScheduleDesignSystem.Colors.primary)
        }
        Slider(value: $fontSize, in: 12...48)
          .padding(.leading, 28)
          .tint(ScheduleDesignSystem.Colors.primary)
      }
    } header: {
      Text(NSLocalizedString("settings_group_font", comment: ""))
        .foregroundColor(ScheduleDesignSystem.Colors.secondaryText)
        .font(ScheduleDesignSystem.Typography.formLabel)
    }
    .listRowBackground(ScheduleDesignSystem.Colors.background)
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

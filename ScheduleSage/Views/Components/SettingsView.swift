//
//  SettingsView.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-20.
//

import SwiftUI

struct SettingsView: View {
  // MARK: - Properties
  @StateObject private var themeManager = ThemeManager.shared
  @State private var showNotificationAlert = false
  @State private var showLaunchError = false
  
  @AppStorage("enableNotifications") private var enableNotifications = true
  @AppStorage("showPreviews") private var showPreviews = true
  @AppStorage("fontSize") private var fontSize: Double = 28
  @AppStorage("useWindowMode") private var useWindowMode = true
  @State private var autoStart = LaunchManager.shared.isLaunchAtStartupEnabled
  
  // MARK: - View
  var body: some View {
    TabView {
      generalSettings
        .tabItem { settingsTabLabel("settings_tab_general", systemImage: "gear") }
        .tag(SettingsTab.general)
      
      advancedSettings
        .tabItem { settingsTabLabel("settings_tab_advanced", systemImage: "star") }
        .tag(SettingsTab.advanced)
    }
    .frame(width: 375, height: 520)
    .tabViewStyle(.automatic)
    .background(ScheduleDesignSystem.Colors.primaryBackground)
    .tint(ScheduleDesignSystem.Colors.primary)
  }
}

// MARK: - View Components
private extension SettingsView {
  var generalSettings: some View {
    SettingsForm {
      notificationSection
      appearanceSection
      systemSection
      versionSection
    }
  }
  
  var advancedSettings: some View {
    SettingsForm {
      previewSection
      fontSection
    }
  }
  
  var notificationSection: some View {
    Section {
      Toggle(isOn: notificationBinding) {
        settingsLabel("settings_notifications", systemImage: "bell.badge")
      }
    } header: {
      Text("settings_section_notifications")
    }
  }
  
  var appearanceSection: some View {
    Section {
      Toggle(isOn: Binding(
        get: { themeManager.isDarkMode },
        set: { themeManager.setDarkMode($0) }
      )) {
        settingsLabel("settings_dark_mode", systemImage: "moon.fill")
      }
    } header: {
      Text("settings_section_appearance")
    }
  }
  
  var systemSection: some View {
    Section {
      Toggle(isOn: $autoStart) {
        settingsLabel("settings_launch_at_login", systemImage: "power")
      }
      .onChange(of: autoStart) { _, newValue in
        handleAutoStartChange(newValue)
      }
      
      Toggle(isOn: $useWindowMode) {
        settingsLabel("settings_use_window_mode", systemImage: "macwindow")
      }
    } header: {
      Text("settings_section_system")
    }
  }
  
  var previewSection: some View {
    Section {
      Toggle(isOn: $showPreviews) {
        settingsLabel("settings_show_previews", systemImage: "eye")
      }
    } header: {
      Text("settings_section_preview")
    }
  }
  
  var fontSection: some View {
    Section {
      HStack {
        settingsLabel("settings_font_size", systemImage: "textformat.size")
        Slider(value: $fontSize, in: 12...48, step: 1)
        Text("\(Int(fontSize))")
      }
    } header: {
      Text("settings_section_font")
    }
  }
  
  var versionSection: some View {
    Section {
      Text("Version \(Bundle.main.shortVersionString)")
        .foregroundColor(ScheduleDesignSystem.Colors.secondaryText)
    }
  }
}

// MARK: - Helper Views
private extension SettingsView {
  func settingsTabLabel(_ title: String, systemImage: String) -> some View {
    Label(NSLocalizedString(title, comment: ""), systemImage: systemImage)
      .labelStyle(.titleAndIcon)
  }
  
  func settingsLabel(_ title: String, systemImage: String) -> some View {
    Label {
      Text(NSLocalizedString(title, comment: ""))
        .foregroundColor(ScheduleDesignSystem.Colors.primaryText)
    } icon: {
      Image(systemName: systemImage)
        .foregroundColor(ScheduleDesignSystem.Colors.primary)
    }
  }
}

// MARK: - Helper Methods
private extension SettingsView {
  var notificationBinding: Binding<Bool> {
    Binding(
      get: { enableNotifications },
      set: { newValue in
        if newValue {
          Task { await requestNotificationPermission() }
        } else {
          enableNotifications = false
        }
      }
    )
  }
  
  func requestNotificationPermission() async {
    let isAuthorized = await NotificationManager.shared.checkNotificationStatus()
    if !isAuthorized {
      NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.notifications")!)
    }
    await MainActor.run {
      enableNotifications = isAuthorized
    }
  }
  
  func handleAutoStartChange(_ newValue: Bool) {
    LaunchManager.shared.setLaunchAtStartup(newValue)
    if !LaunchManager.shared.isLaunchAtStartupEnabled {
      showLaunchError = true
      autoStart = false
    }
  }
}

// MARK: - Helper Views
private struct SettingsForm<Content: View>: View {
  let content: Content
  
  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }
  
  var body: some View {
    Form {
      content
    }
    .formStyle(.grouped)
    .padding(ScheduleDesignSystem.Spacing.contentPadding)
    .background(ScheduleDesignSystem.Colors.primaryBackground)
  }
}

// MARK: - Bundle Extension
private extension Bundle {
  var shortVersionString: String {
    infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
  }
}

#Preview {
  SettingsView()
}

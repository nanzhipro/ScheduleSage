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
    .frame(width: 375, height: 500)
    .fixedSize(horizontal: true, vertical: true)
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
}

// MARK: - Section Views
private extension SettingsView {
  var notificationSection: some View {
    SettingsSection(title: "settings_group_notifications") {
      SettingsToggle(
        title: "settings_notifications",
        icon: "bell.badge",
        isOn: Binding(
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
        )
      )
    }
  }
  
  var appearanceSection: some View {
    SettingsSection(title: "settings_group_appearance") {
      SettingsToggle(
        title: "settings_dark_mode",
        icon: "moon.fill",
        isOn: Binding(
          get: { themeManager.isDarkModeEnabled },
          set: { themeManager.setDarkMode($0) }
        )
      )
    }
  }
  
  var systemSection: some View {
    SettingsSection(title: "settings_group_system") {
      SettingsToggle(
        title: "settings_auto_start",
        icon: "power",
        isOn: Binding(
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
        )
      )
      
      SettingsToggle(
        title: "settings_window_mode",
        icon: "macwindow",
        isOn: $useWindowMode
      )
    }
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
  
  var versionSection: some View {
    SettingsSection(title: "settings_group_about") {
      SettingsRow(title: "settings_version", icon: "info.circle") {
        Text(AppInfo.versionWithBuild)
          .foregroundColor(DesignSystem.Colors.secondaryText)
          .font(DesignSystem.Typography.caption)
      }
      
      ForEach(AboutLink.allCases) { link in
        SettingsLinkRow(link: link)
      }
    }
  }
}

// MARK: - Helper Views
private struct SettingsSection<Content: View>: View {
  let title: LocalizedStringKey
  let content: Content
  
  init(title: LocalizedStringKey, @ViewBuilder content: () -> Content) {
    self.title = title
    self.content = content()
  }
  
  var body: some View {
    Section {
      content
    } header: {
      Text(title)
        .foregroundColor(DesignSystem.Colors.secondaryText)
        .font(DesignSystem.Typography.formLabel)
    }
    .listRowBackground(DesignSystem.Colors.background)
  }
}

private struct SettingsToggle: View {
  let title: LocalizedStringKey
  let icon: String
  let isOn: Binding<Bool>
  
  var body: some View {
    Toggle(isOn: isOn) {
      Label {
        Text(title)
          .foregroundColor(DesignSystem.Colors.primaryText)
      } icon: {
        Image(systemName: icon)
          .foregroundStyle(DesignSystem.Colors.primary)
      }
    }
    .tint(DesignSystem.Colors.primary)
  }
}

private struct SettingsRow<Content: View>: View {
  let title: LocalizedStringKey
  let icon: String
  let content: Content
  
  init(title: LocalizedStringKey, icon: String, @ViewBuilder content: () -> Content) {
    self.title = title
    self.icon = icon
    self.content = content()
  }
  
  var body: some View {
    HStack {
      Label {
        Text(title)
          .foregroundColor(DesignSystem.Colors.primaryText)
      } icon: {
        Image(systemName: icon)
          .foregroundStyle(DesignSystem.Colors.primary)
      }
      Spacer()
      content
    }
  }
}

private struct SettingsLinkRow: View {
  let link: AboutLink
  
  var body: some View {
    Button(action: { link.open() }) {
      Label {
        Text(NSLocalizedString(link.title, comment: ""))
          .foregroundColor(DesignSystem.Colors.primaryText)
      } icon: {
        Image(systemName: link.icon)
          .foregroundStyle(DesignSystem.Colors.primary)
      }
    }
    .buttonStyle(.plain)
  }
}

// MARK: - Models
private enum AboutLink: String, CaseIterable, Identifiable {
  case privacyPolicy
  case termsOfService
  case faq
  
  var id: String { rawValue }
  
  var title: String {
    switch self {
    case .privacyPolicy: return "settings_privacy_policy"
    case .termsOfService: return "settings_terms_of_service"
    case .faq: return "settings_faq"
    }
  }
  
  var icon: String {
    switch self {
    case .privacyPolicy: return "hand.raised.fill"
    case .termsOfService: return "doc.text.fill"
    case .faq: return "questionmark.circle.fill"
    }
  }
  
  var url: String {
    switch self {
    case .privacyPolicy: return "https://tiwenlab.notion.site/18f5180108e580f69c59f212867f9a15"
    case .termsOfService: return "https://tiwenlab.notion.site/18f5180108e5804cb596c845db6754bd"
    case .faq: return "https://tiwenlab.notion.site/FAQ-18f5180108e58034aecdec8a297c97ab?pvs=74"
    }
  }
  
  func open() {
    if let url = URL(string: url) {
      NSWorkspace.shared.open(url)
    }
  }
}

#Preview {
  SettingsView()
}

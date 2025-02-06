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
  
  @AppStorage("currentTheme") private var currentTheme = ThemeType.wechat.rawValue {
    didSet {
      if let theme = ThemeType(rawValue: currentTheme) {
        withAnimation(.easeInOut(duration: 0.2)) {
          DesignSystem.switchTheme(to: theme)
          NotificationCenter.default.post(name: .themeDidChange, object: theme)
        }
      }
    }
  }
  
  @AppStorage("alwaysOnTop") private var alwaysOnTop = false
  
  @StateObject private var themeManager = ThemeManager.shared
  @State private var showNotificationAlert = false
  @State private var autoStart: Bool = LaunchManager.shared.isLaunchAtStartupEnabled
  @State private var showLaunchError = false
  
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
      ThemePicker(currentTheme: Binding(
        get: { ThemeType(rawValue: currentTheme) ?? .wechat },
        set: { currentTheme = $0.rawValue }
      ))
      
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
        title: "settings_always_on_top",
        icon: "rectangle.on.rectangle",
        isOn: $alwaysOnTop
      )
      .onChange(of: alwaysOnTop) { newValue in
        NotificationCenter.default.post(
          name: .windowLevelDidChange,
          object: newValue
        )
      }
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
private extension SettingsView {
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
}

// MARK: - Theme Picker
private struct ThemePicker: View {
  @Binding var currentTheme: ThemeType
  
  var body: some View {
    HStack {
      Label {
        Text("settings_theme")
          .foregroundColor(DesignSystem.Colors.primaryText)
      } icon: {
        Image(systemName: "paintpalette.fill")
          .foregroundStyle(DesignSystem.Colors.primary)
      }
      
      Spacer()
      
      HStack(spacing: 12) {
        ForEach(ThemeType.allCases) { theme in
          ThemeColorButton(
            theme: theme,
            isSelected: theme == currentTheme,
            action: { currentTheme = theme }
          )
        }
      }
    }
    .padding(.vertical, 2)
  }
}

private struct ThemeColorButton: View {
  let theme: ThemeType
  let isSelected: Bool
  let action: () -> Void
  
  @Environment(\.colorScheme) private var colorScheme
  @State private var isHovered = false
  
  var body: some View {
    Button(action: action) {
      Circle()
        .fill(theme.color)
        .frame(
          width: DesignSystem.Dimensions.selectionIndicatorMiddleSize,
          height: DesignSystem.Dimensions.selectionIndicatorMiddleSize
        )
        .overlay(
          Circle()
            .strokeBorder(
              isSelected ? theme.color : .clear,
              lineWidth: 2
            )
            .padding(-4)
        )
        .overlay(
          Circle()
            .fill(.white)
            .frame(
              width: DesignSystem.Dimensions.selectionIndicatorInnerSize,
              height: DesignSystem.Dimensions.selectionIndicatorInnerSize
            )
            .opacity(isSelected ? 1 : 0)
        )
        .shadow(
          color: isHovered ? .black.opacity(0.1) : .clear,
          radius: 4,
          x: 0,
          y: 2
        )
    }
    .buttonStyle(.plain)
    .scaleEffect(isHovered ? 1.1 : 1.0)
    .onHover { hovering in
      withAnimation(.easeInOut(duration: 0.2)) {
        isHovered = hovering
      }
    }
  }
}

private extension ThemeType {
  var color: Color {
    switch self {
    case .apple: return Color(light: "007AFF", dark: "0A84FF")
    case .wechat: return Color(light: "07C160", dark: "07C160")
    case .airbnb: return Color(light: "FF5A5F", dark: "FF5A5F")
    }
  }
  
  var localizedName: LocalizedStringKey {
    switch self {
    case .apple: return "theme_apple"
    case .wechat: return "theme_wechat"
    case .airbnb: return "theme_airbnb"
    }
  }
}

// MARK: - Models
private enum AboutLink: String, CaseIterable, Identifiable {
  case privacyPolicy
  case faq
  
  var id: String { rawValue }
  
  var title: String {
    switch self {
    case .privacyPolicy: return "settings_privacy_policy"
    case .faq: return "settings_faq"
    }
  }
  
  var icon: String {
    switch self {
    case .privacyPolicy: return "hand.raised.fill"
    case .faq: return "questionmark.circle.fill"
    }
  }
  
  var url: String {
    switch self {
    case .privacyPolicy: return "https://tiwenlab.notion.site/18f5180108e580f69c59f212867f9a15"
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

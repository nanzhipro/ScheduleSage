//
//  SettingsView.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-20.
//

import AppKit
import SwiftUI

struct SettingsView: View {
  @AppStorage("currentTheme") private var currentTheme = ThemeType.wechat.rawValue
  @AppStorage("appearanceMode") private var appearanceMode = AppearanceMode.auto.rawValue
  @StateObject private var themeManager = ThemeManager.shared
  @State private var autoStart: Bool = LaunchManager.shared.isLaunchAtStartupEnabled
  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    TabView {
      generalSettings
        .tabItem {
          Label(NSLocalizedString("settings_tab_general", comment: ""), systemImage: "gear")
        }

      supportView
        .tabItem {
          Label(NSLocalizedString("settings_tab_support", comment: ""), systemImage: "questionmark.circle")
        }
    }
    .frame(width: 375, height: 500)
    .fixedSize(horizontal: true, vertical: true)
    .accentColor(DesignSystem.Colors.primary)
    .onAppear(perform: onAppear)
  }

  private var generalSettings: some View {
    Form {
      appearanceSection
      systemSection
      versionSection
    }
    .formStyle(.grouped)
    .scrollContentBackground(.hidden)
    .background(DesignSystem.Colors.primaryBackground)
  }

  private var appearanceSection: some View {
    SettingsSection(title: "settings_group_appearance") {
      // 外观模式选择器
      Picker(
        selection: Binding(
          get: { AppearanceMode(rawValue: appearanceMode) ?? .auto },
          set: { newValue in
            appearanceMode = newValue.rawValue
            updateAppearance(to: newValue)
          }
        )
      ) {
        ForEach(AppearanceMode.allCases) { mode in
          Label {
            Text(mode.localizedName)
          } icon: {
            Image(systemName: mode.systemImage)
              .foregroundStyle(DesignSystem.Colors.primary)
          }
          .tag(mode)
        }
      } label: {
        Label {
          Text("settings_appearance_mode")
        } icon: {
          Image(systemName: "paintbrush.fill")
            .foregroundStyle(DesignSystem.Colors.primary)
        }
      }
      .pickerStyle(.menu)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.vertical, 4)
    }
  }

  private func updateAppearance(to mode: AppearanceMode) {
    switch mode {
    case .light:
      NSApp.appearance = NSAppearance(named: .aqua)
      themeManager.setDarkMode(false)
    case .dark:
      NSApp.appearance = NSAppearance(named: .darkAqua)
      themeManager.setDarkMode(true)
    case .auto:
      NSApp.appearance = nil  // 重置为系统默认
      // 根据当前系统外观设置
      if let isDark = NSApp.effectiveAppearance.isDarkMode {
        themeManager.setDarkMode(isDark)
      }
    }

    // 发送主题变更通知
    NotificationCenter.default.post(name: .themeDidChange, object: nil)
  }

  private func observeSystemAppearanceChanges() {
    // 移除旧的观察者
    DistributedNotificationCenter.default().removeObserver(self)

    // 添加新的观察者
    DistributedNotificationCenter.default().addObserver(
      forName: Notification.Name("AppleInterfaceThemeChangedNotification"),
      object: nil,
      queue: .main
    ) { _ in
      guard AppearanceMode(rawValue: self.appearanceMode) == .auto,
        let isDark = NSApp.effectiveAppearance.isDarkMode
      else { return }

      self.themeManager.setDarkMode(isDark)
    }
  }

  private var supportView: some View {
    ScrollView {
      VStack(spacing: 16) {
        SupportInfoView()
      }
      .padding()
    }
    .background(DesignSystem.Colors.primaryBackground)
  }
}

// MARK: - View Lifecycle
extension SettingsView {
  private func onAppear() {
    // 初始化时设置外观
    if let mode = AppearanceMode(rawValue: appearanceMode) {
      updateAppearance(to: mode)
    }
  }
}

// MARK: - Section Views
private extension SettingsView {
  var systemSection: some View {
    SettingsSection(title: "settings_group_system") {
      SettingsToggle(
        title: "settings_auto_start",
        icon: "power.circle.fill",
        isOn: Binding(
          get: { autoStart },
          set: { newValue in
            let success = LaunchManager.shared.setLaunchAtStartup(newValue)
            if success {
              autoStart = newValue
            } else {
              autoStart = LaunchManager.shared.isLaunchAtStartupEnabled
            }
          }
        )
      )
    }
  }

  var versionSection: some View {
    SettingsSection(title: "settings_group_about") {
      ForEach(AboutLink.allCases) { link in
        SettingsLinkRow(link: link)
      }

      SettingsRow(title: "settings_version", icon: "info.circle.fill") {
        Text(AppInfo.versionWithBuild)
          .foregroundColor(DesignSystem.Colors.secondaryText)
          .font(DesignSystem.Typography.caption)
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
      .withHoverEffect(scale: 1.02, brightness: 0)
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
  case feedback
  case privacyPolicy
  case userAgreement
  case faq

  var id: String { rawValue }

  var title: String {
    switch self {
    case .feedback: return "settings_feedback"
    case .privacyPolicy: return "settings_privacy_policy"
    case .userAgreement: return "settings_user_agreement"
    case .faq: return "settings_faq"
    }
  }

  var icon: String {
    switch self {
    case .feedback: return "megaphone.fill"
    case .privacyPolicy: return "hand.raised.fill"
    case .userAgreement: return "doc.text.fill"
    case .faq: return "questionmark.circle.fill"
    }
  }

  var url: String {
    switch self {
    case .feedback: return AppConstants.URLs.feedback
    case .privacyPolicy: return AppConstants.URLs.privacyPolicy
    case .userAgreement: return AppConstants.URLs.userAgreement
    case .faq: return AppConstants.URLs.faq
    }
  }

  func open() {
    if let url = URL(string: url) {
      NSWorkspace.shared.open(url)
    }
  }
}

// MARK: - NSAppearance Extension
extension NSAppearance {
  var isDarkMode: Bool? {
    switch self.name {
    case .aqua:
      return false
    case .darkAqua:
      return true
    default:
      return nil
    }
  }
}

#Preview {
  SettingsView()
}

import SwiftUI

public struct SettingsView: View {
  @AppStorage("enableNotifications") private var enableNotifications = true
  @AppStorage("darkMode") private var darkMode = false
  @AppStorage("autoStart") private var autoStart = false
  @AppStorage("showPreviews") private var showPreviews = true
  @AppStorage("fontSize") private var fontSize: Double = 28
  @AppStorage("language") private var language = "English"
  @AppStorage("theme") private var theme = "Apple"
  @AppStorage("feedbackDescription") private var feedbackDescription = ""
  @AppStorage("feedbackScreenshot") private var feedbackScreenshot: Data?
  @AppStorage("feedbackEmail") private var feedbackEmail = ""

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

      feedbackSettings
        .tabItem {
          Label(
            NSLocalizedString("settings_tab_feedback", comment: ""),
            systemImage: "envelope.fill"
          )
        }
    }
    .frame(width: 375, height: 300)
  }

  private var generalSettings: some View {
    Form {
      Section {
        Toggle(NSLocalizedString("settings_notifications", comment: ""), isOn: $enableNotifications)
        Toggle(NSLocalizedString("settings_dark_mode", comment: ""), isOn: $darkMode)
        Toggle(NSLocalizedString("settings_auto_start", comment: ""), isOn: $autoStart)
      }

      Section {
        Picker(NSLocalizedString("settings_language", comment: ""), selection: $language) {
          Text("English").tag("English")
          Text("Chinese").tag("Chinese")
          Text("Japanese").tag("Japanese")
        }
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

      Section {
        Picker(NSLocalizedString("settings_theme", comment: ""), selection: $theme) {
          Text("Apple").tag("Apple")
          Text("WeChat").tag("WeChat")
        }
      }
    }
    .formStyle(.grouped)
    .padding()
  }

  private var feedbackSettings: some View {
    Form {
      Section(header: Text(NSLocalizedString("settings_feedback_description", comment: ""))) {
        TextEditor(text: $feedbackDescription)
          .frame(height: 100)
      }

      Section(header: Text(NSLocalizedString("settings_feedback_screenshot", comment: ""))) {
        Button(action: selectScreenshot) {
          Text(NSLocalizedString("settings_feedback_select_screenshot", comment: ""))
        }
      }

      Section(header: Text(NSLocalizedString("settings_feedback_email", comment: ""))) {
        TextField(NSLocalizedString("settings_feedback_email_placeholder", comment: ""), text: $feedbackEmail)
          .keyboardType(.emailAddress)
      }

      Section {
        Button(action: submitFeedback) {
          Text(NSLocalizedString("settings_feedback_submit", comment: ""))
        }
      }
    }
    .formStyle(.grouped)
    .padding()
  }

  private func selectScreenshot() {
    let panel = NSOpenPanel()
    panel.allowedFileTypes = ["png", "jpg", "jpeg"]
    panel.allowsMultipleSelection = false
    if panel.runModal() == .OK, let url = panel.url, let data = try? Data(contentsOf: url) {
      feedbackScreenshot = data
    }
  }

  private func submitFeedback() {
    // Implement feedback submission logic here
  }
}

#Preview {
  SettingsView()
}

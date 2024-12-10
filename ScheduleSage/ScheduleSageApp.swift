import SwiftUI

@main
struct ScheduleSageApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  @AppStorage("language") private var language = "English"
  @AppStorage("theme") private var theme = "Apple"
  @AppStorage("autoStart") private var autoStart = false
  @AppStorage("feedbackDescription") private var feedbackDescription = ""
  @AppStorage("feedbackScreenshot") private var feedbackScreenshot: Data?
  @AppStorage("feedbackEmail") private var feedbackEmail = ""

  var body: some Scene {
    Settings {
      SettingsView()
    }
  }
}

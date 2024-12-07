//
//  ScheduleSageApp.swift
//  ScheduleSage
//
//  Created by 南朋友 on 2024-03-20.
//

import SwiftUI

@main
struct ScheduleSageApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

  var body: some Scene {
    Settings {
      SettingsView()
    }
  }
}

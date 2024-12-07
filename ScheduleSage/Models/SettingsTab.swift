//
//  SettingsTab.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-21.
//

import Foundation

enum SettingsTab: String, CaseIterable {
  case general
  case advanced

  var title: String {
    switch self {
    case .general:
      return NSLocalizedString("settings_tab_general", comment: "")
    case .advanced:
      return NSLocalizedString("settings_tab_advanced", comment: "")
    }
  }

  var iconName: String {
    switch self {
    case .general:
      return "gearshape.fill"
    case .advanced:
      return "star.fill"
    }
  }
}

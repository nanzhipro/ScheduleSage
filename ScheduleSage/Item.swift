//
//  Item.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024/11/26.
//

import Foundation
import SwiftData

@Model
final class Item {
  var timestamp: Date

  init(timestamp: Date) {
    self.timestamp = timestamp
  }
}

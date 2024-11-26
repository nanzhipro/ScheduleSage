//
//  Item.swift
//  ScheduleSage
//
//  Created by 南朋友 on 2024/11/26.
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

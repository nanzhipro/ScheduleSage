//
//  URLExtensions.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-27.
//

import Foundation

extension URL {
    /// 检查是否是有效的网页 URL
    var isValidWebURL: Bool {
        guard let scheme = scheme?.lowercased() else { return false }
        return ["http", "https"].contains(scheme) && !absoluteString.isEmpty
    }
} 
//
//  ProFeature.swift
//  ScheduleSage
//
//  Created by 南朋友 on 2024/03/26.
//

import Foundation

// MARK: - Pro Feature Model
struct ProFeature: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let isProOnly: Bool
    
    // MARK: - Feature Types
    enum Action: String, Codable {
        case ocr
        case export
        case advanced
    }
    
    // MARK: - Predefined Features
    static let allFeatures: [ProFeature] = [
        ProFeature(
            id: "unlimited_ocr",
            name: NSLocalizedString("feature_unlimited_ocr", comment: ""),
            description: NSLocalizedString("feature_unlimited_ocr_desc", comment: ""),
            icon: "text.viewfinder",
            isProOnly: true
        ),
        // 其他特性...
    ]
    
    static let freeFeatures: [ProFeature] = [
        ProFeature(
            id: "basic_ocr",
            name: NSLocalizedString("feature_basic_ocr", comment: ""),
            description: NSLocalizedString("feature_basic_ocr_desc", comment: ""),
            icon: "text.viewfinder",
            isProOnly: false
        ),
        // 其他免费特性...
    ]
} 
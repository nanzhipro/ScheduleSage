//
//  OCRConfiguration.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-20.
//

import Foundation

public struct OCRConfiguration {
    public var minimumConfidence: Float
    public var preferredLanguages: [OCRLanguage]
    public var enableCache: Bool
    public var maxRetries: Int
    
    public init(
        minimumConfidence: Float = 0.3,
        preferredLanguages: [OCRLanguage] = [.chinese, .english, .japanese],
        enableCache: Bool = true,
        maxRetries: Int = 3
    ) {
        self.minimumConfidence = minimumConfidence
        self.preferredLanguages = preferredLanguages
        self.enableCache = enableCache
        self.maxRetries = maxRetries
    }
    
    public static let `default` = OCRConfiguration()
} 
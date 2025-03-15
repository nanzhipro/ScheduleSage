//
//  OCRMetrics.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-20.
//

import Foundation

public struct OCRMetrics {
    public let processingTime: TimeInterval
    public let imageSize: CGSize
    public let recognizedLanguages: [OCRLanguage]
    public let confidence: Float
    public let timestamp: Date
    
    public init(
        processingTime: TimeInterval,
        imageSize: CGSize,
        recognizedLanguages: [OCRLanguage],
        confidence: Float,
        timestamp: Date = Date()
    ) {
        self.processingTime = processingTime
        self.imageSize = imageSize
        self.recognizedLanguages = recognizedLanguages
        self.confidence = confidence
        self.timestamp = timestamp
    }
} 
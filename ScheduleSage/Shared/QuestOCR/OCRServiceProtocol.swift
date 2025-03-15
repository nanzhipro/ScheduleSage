//
//  OCRServiceProtocol.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-20.
//

import Foundation

public protocol OCRServiceConfigurable {
    var configuration: OCRConfiguration { get set }
    var supportedLanguages: [OCRLanguage] { get }
}

public protocol OCRServiceProtocol: OCRServiceConfigurable {
    func recognizeText(
        from imagePath: String,
        preferredLanguages: [OCRLanguage]
    ) async throws -> [OCRResult]
    
    func recognizeText(
        from image: PlatformImage,
        preferredLanguages: [OCRLanguage]
    ) async throws -> [OCRResult]
    
    func collectMetrics() -> OCRMetrics?
} 
//
//  PlatformImage.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-20.
//

import Foundation

#if os(iOS)
import UIKit
public typealias PlatformImage = UIImage
#elseif os(macOS)
import AppKit
public typealias PlatformImage = NSImage
#endif

// MARK: - Platform Image Extensions
public extension PlatformImage {
    #if os(iOS)
    var platformCGImage: CGImage? { cgImage }
    #elseif os(macOS)
    var platformCGImage: CGImage? {
        tiffRepresentation
            .flatMap { CGImageSourceCreateWithData($0 as CFData, nil) }
            .flatMap { CGImageSourceCreateImageAtIndex($0, 0, nil) }
    }
    
    var platformSize: CGSize {
        representations.first
            .map { CGSize(width: CGFloat($0.pixelsWide), height: CGFloat($0.pixelsHigh)) }
            ?? size
    }
    #endif
} 
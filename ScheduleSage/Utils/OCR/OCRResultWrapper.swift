//
//  OCRResultWrapper.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-20.
//

import Foundation

final class OCRResultWrapper: NSObject {
    let result: OCRResult
    
    init(result: OCRResult) {
        self.result = result
        super.init()
    }
} 
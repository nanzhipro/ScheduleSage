//
//  OCRCache.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-20.
//

import Foundation

public final class OCRCache {
    private var cache = NSCache<NSString, OCRResultWrapper>()
    private let queue = DispatchQueue(label: "com.quest.ocrcache", attributes: .concurrent)
    
    public static let shared = OCRCache()
    
    private init() {
        cache.countLimit = 100 // 最多缓存100个结果
    }
    
    public func store(_ result: OCRResult, forKey key: String) {
        queue.async(flags: .barrier) {
            let wrapper = OCRResultWrapper(result: result)
            self.cache.setObject(wrapper, forKey: key as NSString)
        }
    }
    
    public func retrieve(forKey key: String) -> OCRResult? {
        queue.sync {
            return cache.object(forKey: key as NSString)?.result
        }
    }
    
    public func clear() {
        queue.async(flags: .barrier) {
            self.cache.removeAllObjects()
        }
    }
} 
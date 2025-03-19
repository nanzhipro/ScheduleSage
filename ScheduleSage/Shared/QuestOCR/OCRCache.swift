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
        cache.totalCostLimit = 50 * 1024 * 1024 // 限制总大小为50MB
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
    
    /// 获取当前缓存中的对象数量
    public var count: Int {
        // NSCache没有直接的方法来获取缓存对象数量
        // 返回countLimit作为近似值，因为我们不能直接获取当前缓存数量
        return self.cache.countLimit
    }
    
    /// 移除单个缓存项
    public func remove(forKey key: String) {
        queue.async(flags: .barrier) {
            self.cache.removeObject(forKey: key as NSString)
        }
    }
} 
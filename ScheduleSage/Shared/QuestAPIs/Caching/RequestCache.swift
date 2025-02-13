import Alamofire
import Foundation

/// 网络请求缓存管理器
/// - 功能: 提供内存和磁盘二级缓存
/// - 注意: 默认缓存策略为 .useProtocolCachePolicy
final class RequestCache {
  static let shared = RequestCache()

  private let memoryCache = NSCache<NSString, CachedURLResponse>()
  private let diskCache = URLCache.shared

  func cachedResponse(for request: URLRequest) -> CachedURLResponse? {
    // 优先检查内存缓存
    if let memoryResponse = memoryCache.object(forKey: request.cacheKey) {
      return memoryResponse
    }
    // 检查磁盘缓存
    return diskCache.cachedResponse(for: request)
  }

  func storeResponse(_ response: CachedURLResponse, for request: URLRequest) {
    memoryCache.setObject(response, forKey: request.cacheKey)
    diskCache.storeCachedResponse(response, for: request)
  }
}

extension URLRequest {
  var cacheKey: NSString {
    return "\(httpMethod ?? "GET")_\(url?.absoluteString ?? "")" as NSString
  }
}

import Alamofire
import Foundation

/// Unified error type for network operations
/// - Note: Conforms to both localizedError and customNSError for better interoperability
public enum APIError: Error {
  case network(Error)
  case decoding(Error)
  case authRequired
  case server(statusCode: Int)
  case authFailed(Error)
  case tokenStorageError
  case invalidData(reason: String)

  init(error: Error) {
    if let afError = error as? AFError {
      switch afError {
      case .responseValidationFailed(let reason):
        if case .unacceptableStatusCode(let code) = reason {
          self = .server(statusCode: code)
        } else {
          self = .network(error)
        }
      default: self = .network(error)
      }
    } else if let decodingError = error as? DecodingError {
      self = .decoding(decodingError)
    } else {
      self = .network(error)
    }
  }
}

extension APIError: LocalizedError {
  public var errorDescription: String? {
    switch self {
    case .network(let error):
      return "网络通信失败: \(error.localizedDescription)"
    case .decoding(let error):
      return "数据解析错误: \(error.localizedDescription)"
    case .authRequired:
      return "需要重新认证"
    case .server(let code):
      return "服务器错误(\(code))"
    case .authFailed(let error):
      return "认证失败: \(error.localizedDescription)"
    case .tokenStorageError:
      return "令牌存储错误"
    case .invalidData(let reason):
      return "数据无效: \(reason)"
    }
  }
}

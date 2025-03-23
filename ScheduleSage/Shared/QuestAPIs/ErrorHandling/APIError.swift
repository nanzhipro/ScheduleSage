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
  case invalidResponse(description: String)
  case storage(description: String)
  case general(description: String)

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
      return String(format: NSLocalizedString("toast.error.network", comment: "Network error message"), error.localizedDescription)
    case .decoding(let error):
      return String(format: NSLocalizedString("toast.error.decoding", comment: "Data decoding error message"), error.localizedDescription)
    case .authRequired:
      return NSLocalizedString("toast.error.auth_required", comment: "Authentication required error message")
    case .server(let code):
      return String(format: NSLocalizedString("toast.error.server", comment: "Server error message with status code"), "\(code)")
    case .authFailed(let error):
      return String(format: NSLocalizedString("toast.error.auth_failed", comment: "Authentication failed error message"), error.localizedDescription)
    case .tokenStorageError:
      return NSLocalizedString("toast.error.token_storage", comment: "Token storage error message")
    case .invalidData(let reason):
      return String(format: NSLocalizedString("toast.error.invalid_data", comment: "Invalid data error message"), reason)
    case .invalidResponse(let description):
      return String(format: NSLocalizedString("toast.error.invalid_response", comment: "Invalid response error message"), description)
    case .storage(let description):
      return String(format: NSLocalizedString("toast.error.storage", comment: "Storage error message"), description)
    case .general(let description):
      return String(format: NSLocalizedString("toast.error.general", comment: "General error message"), description)
    }
  }
}

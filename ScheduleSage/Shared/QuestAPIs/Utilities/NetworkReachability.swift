import Alamofire
import Foundation

/// 网络可达性状态监控
/// - 功能: 实时监测网络连接状态变化
class NetworkReachability {
  static let shared = NetworkReachability()

  private let monitor = NetworkReachabilityManager()
  private(set) var isConnected: Bool = false

  func startMonitoring() {
    monitor?.startListening { [weak self] status in
      switch status {
      case .reachable:
        self?.isConnected = true
        NotificationCenter.default.post(name: .networkConnected, object: nil)
      case .notReachable, .unknown:
        self?.isConnected = false
        NotificationCenter.default.post(name: .networkDisconnected, object: nil)
      }
    }
  }
}

extension Notification.Name {
  static let networkConnected = Notification.Name("NetworkConnected")
  static let networkDisconnected = Notification.Name("NetworkDisconnected")
}

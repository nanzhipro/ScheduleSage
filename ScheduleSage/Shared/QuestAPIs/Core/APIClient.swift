import Alamofire
import Foundation

/// 网络请求核心处理类
/// - 功能: 管理所有网络请求，处理认证、日志、错误重试等
/// - 注意: 使用单例模式，需先配置环境参数
public final class APIClient {
  // MARK: - 单例配置
  private static var sharedInstance: APIClient?

  /// 配置共享实例
  /// - Parameters:
  ///   - environment: 环境配置
  ///   - tokenProvider: 令牌提供者
  public static func configure(
    with environment: APIEnvironment,
    tokenProvider: TokenProvider
  ) {
    sharedInstance = APIClient(
      environment: environment,
      tokenProvider: tokenProvider
    )
  }

  /// 获取共享实例
  /// - Returns: 已配置的API客户端实例
  public static var shared: APIClient {
    guard let instance = sharedInstance else {
      fatalError("APIClient must be configured with environment before use")
    }
    return instance
  }

  // MARK: - 依赖组件
  private let session: Session
  private let environment: APIEnvironment
  private let tokenProvider: TokenProvider
  private let logger: NetworkLogger

  // MARK: - 初始化
  /// 初始化网络客户端
  /// - 参数:
  ///   - environment: 环境配置
  ///   - tokenProvider: 令牌管理协议实现
  ///   - logger: 网络日志记录器（默认共享实例）
  public init(
    environment: APIEnvironment,
    tokenProvider: TokenProvider,
    logger: NetworkLogger = .shared
  ) {
    self.environment = environment
    self.tokenProvider = tokenProvider
    self.logger = logger

    // 配置URLSession参数
    let configuration = URLSessionConfiguration.af.default
    configuration.timeoutIntervalForRequest = 30
    configuration.headers = environment.defaultHeaders

    // 使用正确的日志方法
    logger.log(
      level: .info,
      message: "Initializing APIClient with environment: \(environment.identifier)"
    )

    // 构建拦截器链
    let interceptor = Interceptor(
      adapter: NetworkHeaderAdapter(
        tokenProvider: tokenProvider,
        logger: logger
      ),
      retrier: TokenRefreshRetrier(
        tokenProvider: tokenProvider,
        logger: logger
      )
    )

    // 创建共享的 session
    self.session = Session(
      configuration: configuration,
      interceptor: interceptor
    )
  }

  // MARK: - 公开接口
  /// 执行网络请求
  /// - 参数:
  ///   - endpoint: 接口端点配置
  ///   - parameters: 请求参数
  ///   - decoder: JSON解码器（默认带蛇形转换）
  /// - 返回: 包含解码结果或错误的Result类型
  @MainActor
  public func request<T: Decodable>(
    _ endpoint: Endpoint,
    parameters: Parameters? = nil,
    decoder: JSONDecoder = .iso8601SnakeCase
  ) async -> Result<T, APIError> {
    // 使用初始化时创建的 session
    let request = session.request(
      environment.baseURL.appendingPathComponent(endpoint.path),
      method: endpoint.method,
      parameters: parameters
    )

    do {
      let value = try await request.serializingDecodable(T.self, decoder: decoder).value
      return .success(value)
    } catch let error as AFError {
      return .failure(APIError(error: error))
    } catch {
      return .failure(APIError(error: error))
    }
  }

  // MARK: - 辅助方法
  /// 安全更新环境配置
  @MainActor
  public func updateEnvironment(_ newEnvironment: APIEnvironment) {
    // 需要停止所有当前请求
    session.cancelAllRequests()
  }

  /// 取消所有进行中的请求
  public func cancelAllRequests() {
    session.cancelAllRequests()
  }

  /// 创建新的认证会话
  /// - Parameter tokenProvider: 令牌提供者
  /// - Returns: 配置了认证的会话实例
  public func authenticatedSession(
    tokenProvider: TokenProvider
  ) -> Session {
    let configuration = URLSessionConfiguration.af.default
    let interceptor = Interceptor(
      adapter: NetworkHeaderAdapter(
        tokenProvider: tokenProvider,
        logger: logger
      ),
      retrier: TokenRefreshRetrier(
        tokenProvider: tokenProvider,
        logger: logger
      )
    )
    return Session(
      configuration: configuration,
      interceptor: interceptor
    )
  }
}

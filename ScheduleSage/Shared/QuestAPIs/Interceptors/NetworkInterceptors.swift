import Alamofire
import Foundation

/// Adapts requests with current authentication headers
/// - Note: Automatically injects Bearer token when available
public struct NetworkHeaderAdapter: RequestAdapter {
  let tokenProvider: TokenProvider
  let logger: NetworkLogger

  public init(tokenProvider: TokenProvider, logger: NetworkLogger) {
    self.tokenProvider = tokenProvider
    self.logger = logger
  }

  public func adapt(
    _ urlRequest: URLRequest,
    for session: Session,
    completion: @escaping (Result<URLRequest, Error>) -> Void
  ) {
    Task {
      var adaptedRequest = urlRequest

      // 更新 token 获取方式
      if let token = await tokenProvider.token {
        adaptedRequest.headers.add(.authorization(bearerToken: token))
        logger.logTokenEvent(.tokenAdded)
      }

      completion(.success(adaptedRequest))
    }
  }
}

/// 管理令牌刷新状态的 actor
private actor RefreshStateActor {
  private(set) var isRefreshing = false
  
  func setRefreshing(_ value: Bool) {
    isRefreshing = value
  }
}

/// Handles token refresh for unauthorized responses
/// - Warning: May create infinite loop if refresh fails repeatedly
public final class TokenRefreshRetrier: RequestRetrier {
  let tokenProvider: TokenProvider
  let logger: NetworkLogger
  private let refreshState = RefreshStateActor()

  public init(tokenProvider: TokenProvider, logger: NetworkLogger) {
    self.tokenProvider = tokenProvider
    self.logger = logger
  }

  public func retry(
    _ request: Request,
    for session: Session,
    dueTo error: Error,
    completion: @escaping (RetryResult) -> Void
  ) {
    Task {
      // 仅处理401未授权状态码
      guard let statusCode = request.response?.statusCode, statusCode == 401 else {
        return completion(.doNotRetryWithError(error))
      }
      
      // 重试次数和刷新状态检查
      guard request.retryCount < 3, !(await refreshState.isRefreshing) else {
        logger.logUnauthorizedAttempt(request: request)
        return completion(.doNotRetryWithError(APIError.authFailed(error)))
      }
      
      await refreshState.setRefreshing(true)
      
      do {
        try await tokenProvider.refreshToken()
        await refreshState.setRefreshing(false)
        logger.logTokenEvent(.refreshSuccess)
        completion(.retry)
      } catch {
        await refreshState.setRefreshing(false)
        logger.logTokenEvent(.refreshFailure(error))
        completion(.doNotRetryWithError(error))
      }
    }
  }
}

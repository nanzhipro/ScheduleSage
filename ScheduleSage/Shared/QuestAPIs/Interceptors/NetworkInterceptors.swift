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

/// Handles token refresh for unauthorized responses
/// - Warning: May create infinite loop if refresh fails repeatedly
public final class TokenRefreshRetrier: RequestRetrier {
  let tokenProvider: TokenProvider
  let logger: NetworkLogger
  private var isRefreshing: Bool

  public init(tokenProvider: TokenProvider, logger: NetworkLogger) {
    self.tokenProvider = tokenProvider
    self.logger = logger
    self.isRefreshing = false
  }

  public func retry(
    _ request: Request,
    for session: Session,
    dueTo error: Error,
    completion: @escaping (RetryResult) -> Void
  ) {
    // 仅处理401未授权状态码
    guard let statusCode = request.response?.statusCode, statusCode == 401 else {
      return completion(.doNotRetryWithError(error))
    }

    // 重试次数和刷新状态检查
    guard request.retryCount < 3, !isRefreshing else {
      logger.logUnauthorizedAttempt(request: request)
      return completion(.doNotRetryWithError(APIError.authFailed(error)))
    }

    isRefreshing = true

    // 使用新的异步刷新方法
    Task {
      do {
        try await tokenProvider.refreshToken()
        self.isRefreshing = false
        self.logger.logTokenEvent(.refreshSuccess)
        completion(.retry)
      } catch {
        self.isRefreshing = false
        self.logger.logTokenEvent(.refreshFailure(error))
        completion(.doNotRetryWithError(error))
      }
    }
  }
}

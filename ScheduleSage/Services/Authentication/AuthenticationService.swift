//
//  AuthenticationService.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-19.
//

import Foundation
import AuthenticationServices
import OSLog

/// 认证服务协议
@MainActor
protocol AuthenticationServiceProtocol {
    var isAuthenticated: Bool { get }
    var currentUser: User? { get }
    func signInWithApple() async throws -> User
    func signOut() async
    func restoreAuthentication() async -> User?
}

/// 认证服务错误类型
enum AuthenticationError: LocalizedError, Identifiable {
    case signInFailed, credentialInvalid, userCancelled
    case unknown(Error)
    
    var id: String {
        switch self {
        case .signInFailed: return "signInFailed"
        case .credentialInvalid: return "credentialInvalid"
        case .userCancelled: return "userCancelled"
        case .unknown(let error): return "unknown.\(error.localizedDescription)"
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .signInFailed: return NSLocalizedString("auth_error_sign_in_failed", comment: "")
        case .credentialInvalid: return NSLocalizedString("auth_error_credential_invalid", comment: "")
        case .userCancelled: return NSLocalizedString("auth_error_user_cancelled", comment: "")
        case .unknown(let error): return error.localizedDescription
        }
    }
}

/// 认证服务实现
@MainActor
final class AuthenticationService: AuthenticationServiceProtocol {
    // MARK: - Properties
    static let shared = AuthenticationService()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "ScheduleSage", category: "Authentication")
    private let userDefaults = UserDefaults.standard
    private let userKey = "currentUser"
    
    private(set) var currentUser: User? {
        get {
            guard let data = userDefaults.data(forKey: userKey),
                  let user = try? JSONDecoder().decode(User.self, from: data)
            else {
                logger.debug("[Login] No stored user found")
                return nil
            }
            logger.debug("[Login] Retrieved stored user: \(user.logDescription)")
            return user
        }
        set {
            if let newValue, let data = try? JSONEncoder().encode(newValue) {
                logger.debug("[Login] Storing user: \(newValue.logDescription)")
                userDefaults.set(data, forKey: userKey)
            } else {
                logger.notice("[Login] Removing stored user")
                userDefaults.removeObject(forKey: userKey)
            }
        }
    }
    
    var isAuthenticated: Bool {
        currentUser != nil
    }
    
    private init() {
        logger.debug("[Login] Authentication service initialized")
    }
    
    fileprivate func saveUser(_ user: User) async {
        logger.debug("[Login] Saving user and initializing services")
        
        // 先保存用户信息
        currentUser = user
        
        do {
            // 初始化 IAP 服务（使用适当的 QoS）
            try await Task.detached(priority: .userInitiated) {
                try await IAPService.shared.login(userId: user.id)
            }.value
            
            logger.debug("[Login] IAP service initialized for user: \(user.id)")
        } catch {
            logger.error("[Login] Failed to initialize IAP service: \(error.localizedDescription)")
            // 注意：我们仍然保持用户登录状态，即使 IAP 初始化失败
        }
    }
    
    func signInWithApple() async throws -> User {
        logger.info("[Login] Starting Apple ID sign in process")
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]
            
            let controller = ASAuthorizationController(authorizationRequests: [request])
            let delegate = AuthorizationDelegate(service: self, continuation: continuation, logger: logger)
            
            controller.delegate = delegate
            controller.presentationContextProvider = delegate
            
            logger.debug("[Login] Performing authorization request")
            controller.performRequests()
            
            // 保持 delegate 的引用直到授权完成
            objc_setAssociatedObject(controller, "delegate", delegate, .OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    func signOut() async {
        logger.info("[Login] Signing out user")
        
        // 先登出 IAP 服务
        await IAPService.shared.logout()
        
        currentUser = nil
        logger.debug("[Login] User signed out")
    }
    
    /// 尝试恢复用户登录状态
    /// - Returns: 如果有存储的用户信息，则返回用户对象；否则返回 nil
    func restoreAuthentication() async -> User? {
        logger.debug("[Login] Attempting to restore authentication")
        
        guard let user = currentUser else {
            logger.notice("[Login] No stored user found")
            return nil
        }
        
        // 初始化 IAP 服务
        do {
            try await Task.detached(priority: .userInitiated) {
                try await IAPService.shared.login(userId: user.id)
            }.value
            logger.info("[Login] Successfully restored authentication and initialized IAP for user: \(user.logDescription)")
            return user
        } catch {
            logger.error("[Login] Failed to initialize IAP service during restore: \(error.localizedDescription)")
            // 即使 IAP 初始化失败，我们仍然返回用户信息
            return user
        }
    }
}

// MARK: - Authorization Delegate
private final class AuthorizationDelegate: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private let continuation: CheckedContinuation<User, Error>
    private weak var service: AuthenticationService?
    private let logger: Logger
    
    init(service: AuthenticationService, continuation: CheckedContinuation<User, Error>, logger: Logger) {
        self.service = service
        self.continuation = continuation
        self.logger = logger
        super.init()
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        NSApplication.shared.windows.first ?? NSWindow()
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let token = credential.identityToken.flatMap({ String(data: $0, encoding: .utf8) })
        else {
            logger.error("[Login] Invalid credentials")
            continuation.resume(throwing: AuthenticationError.credentialInvalid)
            return
        }
        
        let user = User(
            id: credential.user,
            email: credential.email,
            name: credential.fullName?.givenName,
            token: token
        )
        
        Task { @MainActor in
            if let service {
                // 使用 await 等待 saveUser 完成
                await service.saveUser(user)
                continuation.resume(returning: user)
                logger.info("[Login] User authenticated successfully: \(user.logDescription)")
            } else {
                logger.error("[Login] Service not available")
                continuation.resume(throwing: AuthenticationError.signInFailed)
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        if let error = error as? ASAuthorizationError {
            let authError: AuthenticationError = error.code == .canceled ? .userCancelled : .signInFailed
            logger.notice("[Login] \(authError.localizedDescription)")
            continuation.resume(throwing: authError)
        } else {
            logger.error("[Login] Unknown error: \(error.localizedDescription)")
            continuation.resume(throwing: AuthenticationError.unknown(error))
        }
    }
} 
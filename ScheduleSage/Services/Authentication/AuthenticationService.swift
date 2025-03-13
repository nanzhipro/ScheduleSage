//
//  AuthenticationService.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-19.
//

import Foundation
import AuthenticationServices

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
        case .signInFailed: "signInFailed"
        case .credentialInvalid: "credentialInvalid"
        case .userCancelled: "userCancelled"
        case .unknown(let error): "unknown.\(error.localizedDescription)"
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .signInFailed: NSLocalizedString("auth_error_sign_in_failed", comment: "")
        case .credentialInvalid: NSLocalizedString("auth_error_credential_invalid", comment: "")
        case .userCancelled: NSLocalizedString("auth_error_user_cancelled", comment: "")
        case .unknown(let error): error.localizedDescription
        }
    }
}

/// 认证服务实现
@MainActor
final class AuthenticationService: AuthenticationServiceProtocol {
    // MARK: - Properties
    static let shared = AuthenticationService()
    private let logger = LoggerService.makeCompatible(category: "Authentication")
    private let userDefaults = UserDefaults.standard
    private let userKey = "currentUser"
    
    var isAuthenticated: Bool { currentUser != nil }
    
    private(set) var currentUser: User? {
        get {
            guard let data = userDefaults.data(forKey: userKey),
                  let user = try? JSONDecoder().decode(User.self, from: data)
            else {
                logger.debug("[Login] No stored user found")
                return nil
            }
            return user
        }
        set {
            if let user = newValue {
                if let data = try? JSONEncoder().encode(user) {
                    userDefaults.set(data, forKey: userKey)
                    logger.debug("[Login] Stored user: \(user.logDescription)")
                }
            } else {
                userDefaults.removeObject(forKey: userKey)
                logger.debug("[Login] Removed stored user")
            }
        }
    }
    
    private init() {}
    
    func signInWithApple() async throws -> User {
        logger.info("[Login] Starting Apple ID sign in")
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]
            
            let controller = ASAuthorizationController(authorizationRequests: [request])
            let delegate = AuthorizationDelegate(service: self, continuation: continuation, logger: logger)
            
            controller.delegate = delegate
            controller.presentationContextProvider = delegate
            
            Task(priority: .userInitiated) { @MainActor in
                controller.performRequests()
            }
            
            objc_setAssociatedObject(controller, "delegate", delegate, .OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    func saveUser(_ user: User) async {
        currentUser = user
        
        do {
            try await Task.detached(priority: .userInitiated) {
                try await IAPService.shared.login(userId: user.id)
            }.value
            logger.debug("[Login] IAP service initialized")
        } catch {
            logger.error("[Login] IAP service initialization failed: \(error.localizedDescription)")
        }
    }
    
    func signOut() async {
        await Task.detached(priority: .userInitiated) {
            await IAPService.shared.logout()
        }.value
        
        currentUser = nil
        logger.info("[Login] Sign out completed")
    }
    
    func restoreAuthentication() async -> User? {
        guard let user = currentUser else { return nil }
        
        do {
            try await Task.detached(priority: .userInitiated) {
                try await IAPService.shared.login(userId: user.id)
            }.value
            logger.debug("[Login] Authentication restored")
            return user
        } catch {
            logger.error("[Login] IAP service initialization failed: \(error.localizedDescription)")
            return user
        }
    }
}

// MARK: - Authorization Delegate
private final class AuthorizationDelegate: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private let continuation: CheckedContinuation<User, Error>
    private weak var service: AuthenticationService?
    private let logger: LoggerService
    
    init(service: AuthenticationService, continuation: CheckedContinuation<User, Error>, logger: LoggerService) {
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

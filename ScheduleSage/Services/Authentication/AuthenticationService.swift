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
}

/// 认证服务错误类型
enum AuthenticationError: LocalizedError, Identifiable {
    case signInFailed
    case credentialInvalid
    case userCancelled
    case unknown(Error)
    
    // 添加 Identifiable 协议要求的 id
    var id: String {
        switch self {
        case .signInFailed:
            return "signInFailed"
        case .credentialInvalid:
            return "credentialInvalid"
        case .userCancelled:
            return "userCancelled"
        case .unknown(let error):
            return "unknown.\(error.localizedDescription)"
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .signInFailed:
            return NSLocalizedString("auth_error_sign_in_failed", comment: "")
        case .credentialInvalid:
            return NSLocalizedString("auth_error_credential_invalid", comment: "")
        case .userCancelled:
            return NSLocalizedString("auth_error_user_cancelled", comment: "")
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}

/// 认证服务实现
@MainActor
final class AuthenticationService: AuthenticationServiceProtocol {
    // MARK: - Properties
    static let shared = AuthenticationService()
    private let userDefaults = UserDefaults.standard
    private let tokenKey = "appleIDToken"
    private let userKey = "currentUser"
    private let logger: Logger
    
    private(set) var currentUser: User? {
        get {
            guard let data = userDefaults.data(forKey: userKey),
                  let user = try? JSONDecoder().decode(User.self, from: data)
            else {
                logger.debug("[Login] No stored user found")
                return nil
            }
            logger.debug("[Login] Retrieved stored user: \(user.id)")
            return user
        }
        set {
            guard let newValue = newValue,
                  let data = try? JSONEncoder().encode(newValue)
            else {
                logger.notice("[Login] Removing stored user")
                userDefaults.removeObject(forKey: userKey)
                return
            }
            logger.debug("[Login] Storing user: \(newValue.id)")
            userDefaults.set(data, forKey: userKey)
        }
    }
    
    var isAuthenticated: Bool {
        let status = currentUser != nil
        logger.debug("[Login] Authentication status checked: \(status)")
        return status
    }
    
    private init() {
        self.logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "ScheduleSage", category: "Authentication")
        logger.debug("[Login] Authentication service initialized")
    }
    
    func signInWithApple() async throws -> User {
        logger.info("[Login] Starting Apple ID sign in process")
        
        return try await withCheckedThrowingContinuation { continuation in
            let appleIDProvider = ASAuthorizationAppleIDProvider()
            let request = appleIDProvider.createRequest()
            request.requestedScopes = [.fullName, .email]
            
            logger.debug("[Login] Created authorization request with scopes: \(request.requestedScopes?.description ?? "none")")
            
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
        currentUser = nil
        userDefaults.removeObject(forKey: tokenKey)
        logger.debug("[Login] User signed out, cleared credentials")
    }
    
    func saveUser(_ user: User) {
        logger.info("[Login] Saving user: \(user.id)")
        currentUser = user
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
        logger.debug("[Login] Providing presentation anchor for authorization")
        #if os(iOS)
        return UIApplication.shared.windows.first!
        #else
        // 修改为更安全的窗口获取方式
        guard let window = NSApplication.shared.windows.first else {
            logger.error("[Login] No window found for presentation anchor")
            return NSWindow()
        }
        logger.debug("[Login] Found window for presentation anchor: \(window)")
        return window
        #endif
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        logger.info("[Login] Authorization completed, processing credentials")
        
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            logger.error("[Login] Invalid credential type received")
            continuation.resume(throwing: AuthenticationError.credentialInvalid)
            return
        }
        
        logger.debug("[Login] Received credential for user: \(credential.user)")
        
        guard let identityToken = credential.identityToken else {
            logger.error("[Login] No identity token in credential")
            continuation.resume(throwing: AuthenticationError.credentialInvalid)
            return
        }
        
        guard let token = String(data: identityToken, encoding: .utf8) else {
            logger.error("[Login] Could not decode identity token")
            continuation.resume(throwing: AuthenticationError.credentialInvalid)
            return
        }
        
        logger.debug("[Login] Successfully decoded identity token")
        
        let user = User(
            id: credential.user,
            email: credential.email,
            name: credential.fullName?.givenName,
            token: token
        )
        
        logger.info("[Login] Created user object, saving to service, \(user)")
        
        Task { @MainActor in
            if let service = self.service {
                logger.debug("[Login] Service available, saving user")
                service.saveUser(user)
                continuation.resume(returning: user)
            } else {
                logger.error("[Login] Service not available")
                continuation.resume(throwing: AuthenticationError.signInFailed)
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        if let error = error as? ASAuthorizationError {
            switch error.code {
            case .canceled:
                logger.notice("[Login] User cancelled the authorization")
                continuation.resume(throwing: AuthenticationError.userCancelled)
            default:
                logger.error("[Login] Authorization failed with error: \(error.localizedDescription)")
                continuation.resume(throwing: AuthenticationError.signInFailed)
            }
        } else {
            logger.error("[Login] Unknown error occurred during authorization: \(error.localizedDescription)")
            continuation.resume(throwing: AuthenticationError.unknown(error))
        }
    }
} 
//
//  AuthenticationViewModel.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-19.
//

import Foundation
import SwiftUI

@MainActor
final class AuthenticationViewModel: ObservableObject {
    static let shared = AuthenticationViewModel()
    private let logger = LoggerService.makeCompatible(category: "Authentication")
    
    @Published private(set) var isAuthenticated = false {
        willSet {
            if newValue != isAuthenticated {
                logger.debug("[Login] Authentication status will change: \(self.isAuthenticated) -> \(newValue)")
            }
        }
    }
    @Published private(set) var isLoading = false
    @Published var error: AuthenticationError?
    
    // Toast 相关状态
    @Published var showToast = false
    @Published var toastMessage = ""
    @Published var toastType: ToastType = .error
    
    private let authService: AuthenticationServiceProtocol
    
    var currentUser: User? {
        authService.currentUser
    }
    
    init() {
        // 从 AuthenticationService 获取初始状态
        self.authService = AuthenticationService.shared
        self.isAuthenticated = self.authService.isAuthenticated
        logger.debug("[Login] ViewModel initialized with auth status: \(self.isAuthenticated)")
    }
    
    func signInWithApple() async {
        logger.info("[Login] Starting sign in process")
        isLoading = true
        error = nil
        
        do {
            let user = try await authService.signInWithApple()
            logger.info("[Login] Sign in successful for user: \(user.id)")
            isAuthenticated = true
        } catch let error as AuthenticationError {
            logger.error("[Login] Sign in failed with error: \(error.localizedDescription)")
            self.error = error
            // 显示 toast
            toastMessage = error.localizedDescription
            toastType = .error
            showToast = true
        } catch {
            logger.error("[Login] Sign in failed with unknown error: \(error.localizedDescription)")
            self.error = .unknown(error)
            // 显示 toast
            toastMessage = NSLocalizedString("unknown_error", comment: "")
            toastType = .error
            showToast = true
        }
        
        isLoading = false
        logger.debug("[Login] Sign in process completed, loading state reset")
    }
    
    func signOut() async {
        logger.info("[Login] Starting sign out process")
        await authService.signOut()
        isAuthenticated = false
        logger.info("[Login] Sign out completed")
    }
} 

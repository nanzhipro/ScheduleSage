//
//  LoginView.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-19.
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject private var viewModel: AuthenticationViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    // 添加动画状态
    @State private var isAnimatingOut = false
    
    var body: some View {
        ZStack {
            // 背景渐变
            DesignSystem.Gradients.containerBackground(colorScheme: colorScheme)
                .ignoresSafeArea()
            
            // 主要内容容器
            VStack(spacing: 80) {
                // Logo 和标题
                VStack(spacing: DesignSystem.Spacing.elementSpacing) {
                    Image(systemName: "calendar")
                        .font(.system(size: 60))
                        .foregroundColor(DesignSystem.Colors.primary)
                    
                    Text(AppInfo.name)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    DesignSystem.Colors.primary,
                                    DesignSystem.Colors.primary.opacity(0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(
                            color: colorScheme == .dark ? 
                                DesignSystem.Colors.primary.opacity(0.3) : 
                                .clear,
                            radius: 10
                        )
                    
                    Text(NSLocalizedString("login_subtitle", comment: ""))
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .opacity(0.8)
                }
                
                // 登录按钮
                VStack(spacing: DesignSystem.Spacing.elementSpacing) {
                    ZStack {
                        // 登录按钮
                        Button {
                            Task {
                                await viewModel.signInWithApple()
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "apple.logo")
                                    .font(.system(size: 20, weight: .medium))
                                
                                Text(NSLocalizedString("sign_in_with_apple", comment: ""))
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .frame(width: 280)
                            .frame(height: DesignSystem.Dimensions.largeButtonHeight)
                            .background(colorScheme == .dark ? .white : .black)
                            .foregroundColor(colorScheme == .dark ? .black : .white)
                            .cornerRadius(DesignSystem.Dimensions.buttonCornerRadius)
                        }
                        .buttonStyle(.plain)
                        .opacity(viewModel.isLoading ? 0.6 : 1.0)
                        .disabled(viewModel.isLoading)
                        
                        // Loading 指示器
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .scaleEffect(0.8)
                                .tint(colorScheme == .dark ? .black : .white)
                        }
                    }
                }
            }
        }
        .toast(
            isPresented: $viewModel.showToast,
            type: viewModel.toastType,
            message: viewModel.toastMessage
        )
        // 添加动画修饰符
        .opacity(isAnimatingOut ? 0 : 1)
        .scaleEffect(isAnimatingOut ? 0.9 : 1)
        .onChange(of: viewModel.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isAnimatingOut = true
                }
            }
        }
    }
} 
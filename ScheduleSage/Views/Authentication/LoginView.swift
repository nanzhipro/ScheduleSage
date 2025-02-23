//
//  LoginView.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-19.
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject private var viewModel: AuthenticationViewModel  // 改为 EnvironmentObject
    @Environment(\.colorScheme) private var colorScheme
    
    // 添加动画状态
    @State private var isAnimatingOut = false
    
    var body: some View {
        ZStack {
            // 背景渐变
            DesignSystem.Gradients.containerBackground(colorScheme: colorScheme)
                .ignoresSafeArea()
            
            VStack(spacing: DesignSystem.Spacing.largeContentSpacing) {
                Spacer()
                
                // Logo 和标题
                VStack(spacing: DesignSystem.Spacing.elementSpacing) {
                    Image(systemName: "calendar")
                        .font(.system(size: 60))
                        .foregroundColor(DesignSystem.Colors.primary)
                    
                    Text(AppInfo.name)
                        .font(DesignSystem.Typography.title)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    Text(NSLocalizedString("login_subtitle", comment: ""))
                        .font(DesignSystem.Typography.largeHeaderSubtitle)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DesignSystem.Spacing.horizontal)
                }
                
                Spacer()
                
                // 登录按钮
                VStack(spacing: DesignSystem.Spacing.elementSpacing) {
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
                    .frame(maxWidth: .infinity, alignment: .center)
                    
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(0.8)
                    }
                }
                .padding(.bottom, DesignSystem.Spacing.vertical)
            }
            .padding(DesignSystem.Layout.largeContainerPadding)
        }
        .alert(item: $viewModel.error) { error in
            Alert(
                title: Text(NSLocalizedString("login_error_title", comment: "")),
                message: Text(error.localizedDescription),
                dismissButton: .default(Text(NSLocalizedString("ok", comment: "")))
            )
        }
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
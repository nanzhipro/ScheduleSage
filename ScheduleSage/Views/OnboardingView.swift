//
//  OnboardingView.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-21.
//

import SwiftUI

private struct OnboardingCompletionKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

extension EnvironmentValues {
    var onboardingCompletion: () -> Void {
        get { self[OnboardingCompletionKey.self] }
        set { self[OnboardingCompletionKey.self] = newValue }
    }
}

/// OnboardingView
/// Onboarding 引导页面
/// 展示 App 功能介绍和权限请求
struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.onboardingCompletion) private var onboardingCompletion
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景
                backgroundView
                
                VStack(spacing: 0) {
                    // 页面内容
                    TabView(selection: $viewModel.currentPageIndex) {
                        ForEach(Array(viewModel.pages.enumerated()), id: \.element.id) { index, page in
                            OnboardingPageView(page: page, viewModel: viewModel)
                                .tag(index)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                        }
                    }
                    .tabViewStyle(.automatic)
                    .animation(.spring(), value: viewModel.currentPageIndex)
                    
                    // 底部控制栏
                    bottomControlBar
                }
                .padding(.vertical, 40)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .frame(width: DesignSystem.Dimensions.mainViewWidth, height: DesignSystem.Dimensions.mainViewHeight)
        .background(DesignSystem.Colors.background)
    }
    
    // MARK: - Subviews
    
    private var backgroundView: some View {
        ZStack {
            // 动态模糊背景
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
            
            // 渐变背景
            LinearGradient(
                colors: [
                    DesignSystem.Colors.primary.opacity(0.1),
                    DesignSystem.Colors.secondaryGray.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .ignoresSafeArea()
    }
    
    private var bottomControlBar: some View {
        HStack {
            // 返回按钮
            if viewModel.canGoBack {
                Button(action: { viewModel.goToPreviousPage() }) {
                    Label(
                        NSLocalizedString("onboarding.button.back", comment: ""),
                        systemImage: "chevron.left"
                    )
                }
                .buttonStyle(.plain)
                .foregroundColor(DesignSystem.Colors.primary)
            }
            
            Spacer()
            
            // 页面指示器
            PageIndicator(
                numberOfPages: viewModel.pages.count,
                currentPage: viewModel.currentPageIndex
            )
            
            Spacer()
            
            // 下一步/完成按钮
            if viewModel.isLastPage {
                Button(action: {
                    viewModel.finish()
                    onboardingCompletion()
                }) {
                    Text("onboarding.button.finish")
                        .fontWeight(.medium)
                }
                .buttonStyle(.borderedProminent)
                .tint(DesignSystem.Colors.primary)
            } else {
                Button(action: { viewModel.goToNextPage() }) {
                    Label(
                        NSLocalizedString("onboarding.button.next", comment: ""),
                        systemImage: "chevron.right"
                    )
                }
                .buttonStyle(.plain)
                .foregroundColor(DesignSystem.Colors.primary)
            }
        }
        .padding(.horizontal, 40)
        .padding(.top, 20)
    }
}

// MARK: - Helper Views

/// 页面指示器
private struct PageIndicator: View {
    let numberOfPages: Int
    let currentPage: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<numberOfPages, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? DesignSystem.Colors.primary : DesignSystem.Colors.secondaryGray)
                    .frame(width: 8, height: 8)
                    .animation(.spring(), value: currentPage)
            }
        }
    }
}

/// 视觉效果视图
private struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

// MARK: - Preview

#Preview {
    OnboardingView()
}
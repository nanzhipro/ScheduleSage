//
//  ToastView.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-21.
//

import SwiftUI

// MARK: - Toast Type
public enum ToastType {
    case success
    case error
}

// MARK: - Toast Configuration
public struct ToastConfiguration {
    let type: ToastType
    let message: String
    let duration: TimeInterval
    
    public init(type: ToastType, message: String, duration: TimeInterval = 2.0) {
        self.type = type
        self.message = message
        self.duration = duration
    }
}

// MARK: - Toast View
public struct ToastView: View {
    private let configuration: ToastConfiguration
    
    public init(configuration: ToastConfiguration) {
        self.configuration = configuration
    }
    
    public var body: some View {
        HStack(spacing: 8) {
            Image(systemName: configuration.type == .success ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(.white)
            
            Text(configuration.message)
                .font(ScheduleDesignSystem.Typography.bodyRegular)
                .foregroundColor(.white)
                .lineLimit(2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(configuration.type == .success ? ScheduleDesignSystem.Colors.success : ScheduleDesignSystem.Colors.error)
        .cornerRadius(ScheduleDesignSystem.Dimensions.cardCornerRadius)
        .shadow(
            color: Color.black.opacity(0.1),
            radius: 10,
            x: 0,
            y: 4
        )
        .frame(maxWidth: 300)
    }
}

// MARK: - Toast Container
public struct ToastContainer<Content: View>: View {
    @Binding private var isPresented: Bool
    private let configuration: ToastConfiguration
    private let content: Content
    
    public init(
        isPresented: Binding<Bool>,
        configuration: ToastConfiguration,
        @ViewBuilder content: () -> Content
    ) {
        self._isPresented = isPresented
        self.configuration = configuration
        self.content = content()
    }
    
    public var body: some View {
        ZStack {
            content
            
            if isPresented {
                VStack {
                    Spacer()
                    ToastView(configuration: configuration)
                        .transition(.moveAndFade())
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + configuration.duration) {
                                withAnimation(.spring(response: 0.3)) {
                                    isPresented = false
                                }
                            }
                        }
                    Spacer()
                }
            }
        }
        .animation(.spring(response: 0.3), value: isPresented)
    }
}

// MARK: - View Extensions
public extension View {
    func toast(
        isPresented: Binding<Bool>,
        type: ToastType,
        message: String,
        duration: TimeInterval = 2.0
    ) -> some View {
        ToastContainer(
            isPresented: isPresented,
            configuration: .init(type: type, message: message, duration: duration)
        ) {
            self
        }
    }
}

private extension AnyTransition {
    static func moveAndFade() -> AnyTransition {
        .move(edge: .top).combined(with: .opacity)
    }
}

// MARK: - Preview Provider
#if DEBUG
struct ToastView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ToastView(configuration: .init(type: .success, message: "操作成功完成"))
                .previewDisplayName("Success Toast")
            
            ToastView(configuration: .init(type: .error, message: "发生错误，请重试"))
                .previewDisplayName("Error Toast")
            
            DemoView()
                .previewDisplayName("Toast Container Demo")
        }
        .previewLayout(.sizeThatFits)
        .padding()
    }
}

private struct DemoView: View {
    @State private var showToast = false
    
    var body: some View {
        VStack {
            Button("Show Toast") {
                showToast = true
            }
        }
        .frame(width: 300, height: 200)
        .toast(isPresented: $showToast, type: .success, message: "这是一个测试消息")
    }
}
#endif 
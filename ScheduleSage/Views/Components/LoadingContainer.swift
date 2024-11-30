import SwiftUI

struct LoadingContainer<Content: View>: View {
    @StateObject private var loadingManager = LoadingManager.shared
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            // 主要内容
            content
            
            // 加载遮罩和指示器
            if loadingManager.isLoading {
                Color.black
                    .opacity(0.2)
                    .edgesIgnoringSafeArea(.all)
                
                LoadingIndicator(type: loadingManager.loadingType)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: loadingManager.isLoading)
    }
}

// 视图扩展，使用更方便
extension View {
    func withLoading() -> some View {
        LoadingContainer { self }
    }
} 
import SwiftUI

class PopoverViewModel: ObservableObject {
    @Published var showEventList: Bool = false
    @Published var isDragging: Bool = false
    @Published var dragAnimation: DragAnimation = .none
    @Published var isOCRProcessing: Bool = false
    
    private let clipboardManager = ClipboardManager()
    
    enum DragAnimation {
        case none
        case pulse
        case bounce
        case glow
        case scale
        
        var animation: Animation {
            switch self {
            case .none:
                return .default
            case .pulse:
                return Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)
            case .bounce:
                return Animation.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0.3)
            case .glow:
                return Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true)
            case .scale:
                return Animation.easeInOut(duration: 0.5)
            }
        }
    }
    
    func checkClipboardContent() {
        if let content = clipboardManager.checkClipboard() {
            print(content.description)
        }
    }
    
    func resetState() {
        showEventList = false
        isDragging = false
        dragAnimation = .none
        checkClipboardContent()
    }
    
    func handleDragEntered() {
        print("🔵 ViewModel - handleDragEntered")
        isDragging = true
        dragAnimation = .glow
    }
    
    func handleDragExited() {
        print("🔵 ViewModel - handleDragExited")
        isDragging = false
        dragAnimation = .none
    }
    
    func handleDropped(_ urls: [URL]) {
        print("🔵 ViewModel - handleDropped started")
        isDragging = false
        dragAnimation = .none
        
        guard let url = urls.first else {
            print("🔴 ViewModel - No URL provided")
            return
        }
        
        let absolutePath = url.path
        print("🟢 ViewModel - Processing dropped image at: \(absolutePath)")
        processDroppedImage(at: absolutePath)
    }
    
    private func processDroppedImage(at path: String) {
        print("🟢 ViewModel - Ready to process image at path: \(path)")
        // TODO: 实现图片处理逻辑
    }
} 
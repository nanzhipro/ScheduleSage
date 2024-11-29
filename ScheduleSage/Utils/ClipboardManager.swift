import AppKit
import Combine

class ClipboardManager: ObservableObject {
    @Published var lastChangeCount: Int = NSPasteboard.general.changeCount
    private var timer: Timer?
    private let checkInterval: TimeInterval = 0.5
    
    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: checkInterval, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    private func checkClipboard() {
        let pasteboard = NSPasteboard.general
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount
        
        if let url = pasteboard.string(forType: .string), URL(string: url) != nil {
            print("Clipboard changed: URL detected - \(url)")
        } else if let imageData = pasteboard.data(forType: .tiff) {
            print("Clipboard changed: Image detected - \(imageData.count) bytes")
        }
    }
} 
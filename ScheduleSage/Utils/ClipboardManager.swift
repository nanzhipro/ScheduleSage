import AppKit

class ClipboardManager: ObservableObject {
    private let supportedImageExtensions = ["jpg", "jpeg", "png", "gif", "heic"]
    
    func checkClipboard() -> ClipboardContent? {
        let pasteboard = NSPasteboard.general
        
        // 检查 URL
        if let urlString = pasteboard.string(forType: .string),
           let url = URL(string: urlString) {
            return .url(url)
        }
        
        // 检查图片文件
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self]) as? [URL],
           let imageURL = urls.first,
           let fileExtension = imageURL.pathExtension.lowercased() as String?,
           supportedImageExtensions.contains(fileExtension) {
            return .image(imageURL)
        }
        
        return nil
    }
} 
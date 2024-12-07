import AppKit

class ClipboardManager: ObservableObject {
  func checkClipboard() -> ClipboardContent? {
    let pasteboard = NSPasteboard.general

    // 检查 URL
    if let urlString = pasteboard.string(forType: .string),
      let url = URL(string: urlString)
    {
      return .url(url)
    }

    // 检查图片文件
    if let urls = pasteboard.readObjects(forClasses: [NSURL.self]) as? [URL],
      let imageURL = urls.first,
      ImageSupport.isSupported(url: imageURL)
    {
      return .image(imageURL)
    }

    return nil
  }
}

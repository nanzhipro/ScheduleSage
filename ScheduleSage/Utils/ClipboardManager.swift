import AppKit

class ClipboardManager: ObservableObject {
  func checkClipboard() -> ClipboardContent? {
    let pasteboard = NSPasteboard.general
    
    // 1. 优先检查文件引用
    if let urls = pasteboard.readObjects(forClasses: [NSURL.self]) as? [URL],
      let fileURL = urls.first
    {
      // 检查是否是图片文件
      if ImageSupport.isSupported(url: fileURL) && FileManager.default.fileExists(atPath: fileURL.path) {
        return .image(fileURL)
      }
      
      // 如果不是图片文件，但是有效的 Web URL，返回 URL 类型
      if fileURL.isValidWebURL {
        return .url(fileURL)
      }
    }
    
    // 2. 检查图片数据
    if let image = NSImage(pasteboard: pasteboard) {
      // 保存图片到临时文件
      let tempURL = saveImageToTemp(image)
      return tempURL.map { .image($0) }
    }
    
    // 3. 最后检查 URL 字符串
    if let urlString = pasteboard.string(forType: .string),
      let url = URL(string: urlString),
      url.isValidWebURL
    {
      return .url(url)
    }
    
    return nil
  }
  
  private func saveImageToTemp(_ image: NSImage) -> URL? {
    guard let tiffData = image.tiffRepresentation,
          let imageRep = NSBitmapImageRep(data: tiffData),
          let imageData = imageRep.representation(using: .png, properties: [:])
    else { return nil }
    
    let tempDir = FileManager.default.temporaryDirectory
    let fileName = "\(UUID().uuidString).png"
    let fileURL = tempDir.appendingPathComponent(fileName)
    
    do {
      try imageData.write(to: fileURL)
      return fileURL
    } catch {
      return nil
    }
  }
}

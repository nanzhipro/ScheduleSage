import AppKit

enum ClipboardContent {
  case url(URL)
  case image(URL)
  case text(String)

  var description: String {
    switch self {
    case .url(let url):
      return "URL: \(url.absoluteString)"
    case .image(let url):
      return "Image path: \(url.path)"
    case .text(let content):
      return "Text content: \(content.prefix(30))..."
    }
  }
}

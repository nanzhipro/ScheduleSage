import SwiftUI
import UniformTypeIdentifiers
import OSLog

struct ImageDropDelegate: DropDelegate {
  let onDrop: ([URL]) -> Void
  let onEntered: () -> Void
  let onExited: () -> Void
  let onOCRStateChange: (Bool) -> Void
  
  private let processor: OCRProcessor
  private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "ScheduleSage", category: "ImageDropDelegate")

  init(
    onDrop: @escaping ([URL]) -> Void,
    onEntered: @escaping () -> Void,
    onExited: @escaping () -> Void,
    onOCRStateChange: @escaping (Bool) -> Void,
    processor: OCRProcessor = OCRProcessor()
  ) {
    self.onDrop = onDrop
    self.onEntered = onEntered
    self.onExited = onExited
    self.onOCRStateChange = onOCRStateChange
    self.processor = processor
  }

  func performDrop(info: DropInfo) -> Bool {
    let providers = info.itemProviders(for: [.fileURL])
    logger.debug("Found \(providers.count) providers")
    
    guard let provider = providers.first else {
      logger.error("No valid providers available")
      return false
    }
    
    guard provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) else {
      logger.error("Provider lacks file URL")
      return false
    }
    
    Task {
      do {
        let urlData = try await provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) as? Data
        guard let urlData = urlData,
              let url = URL(dataRepresentation: urlData, relativeTo: nil) else {
          logger.error("Invalid URL data")
          return
        }
        
        logger.debug("Processing file at: \(url.path)")
        await MainActor.run {
          onDrop([url])
        }
      } catch {
        logger.error("Error loading item: \(error.localizedDescription)")
      }
    }
    
    return true
  }

  func validateDrop(info: DropInfo) -> Bool {
    info.hasItemsConforming(to: [.fileURL])
  }

  func dropEntered(info: DropInfo) {
    onEntered()
  }

  func dropExited(info: DropInfo) {
    onExited()
  }
}

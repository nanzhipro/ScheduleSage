import SwiftUI
import UniformTypeIdentifiers
import QuestOCR

@MainActor
struct ImageDropDelegate: DropDelegate {
  let onDrop: ([URL]) -> Void
  let onEntered: () -> Void
  let onExited: () -> Void
  let onOCRStateChange: (Bool) -> Void
  
  private let processor: OCRProcessor
  private let logger = LoggerService.makeCompatible(category: "ImageDropDelegate")

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
    
    Task { @MainActor in
      do {
        let urlData = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Data?, Error>) in
          provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { data, error in
            if let error = error {
              continuation.resume(throwing: error)
            } else {
              continuation.resume(returning: data as? Data)
            }
          }
        }
        
        guard let urlData = urlData,
              let url = URL(dataRepresentation: urlData, relativeTo: nil) else {
          logger.error("Invalid URL data")
          return
        }
        
        logger.debug("Processing file at: \(url.path)")
        onDrop([url])
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

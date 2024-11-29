import SwiftUI
import UniformTypeIdentifiers

struct ImageDropDelegate: DropDelegate {
    let onDrop: ([NSImage]) -> Void
    
    func performDrop(info: DropInfo) -> Bool {
        let providers = info.itemProviders(for: [.fileURL])
        
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { item, error in
                    guard let url = item as? URL,
                          let image = NSImage(contentsOf: url) else { return }
                    
                    DispatchQueue.main.async {
                        print("Image dropped: \(url.lastPathComponent)")
                        onDrop([image])
                    }
                }
                return true
            }
        }
        return false
    }
    
    func validateDrop(info: DropInfo) -> Bool {
        return info.hasItemsConforming(to: [.fileURL])
    }
} 

import SwiftUI

enum LoadingType {
    case ocr
    case network
    case processing
    case custom(String)
    
    var message: String {
        switch self {
        case .ocr:
            return NSLocalizedString("loading_ocr", comment: "")
        case .network:
            return NSLocalizedString("loading_network", comment: "")
        case .processing:
            return NSLocalizedString("loading_processing", comment: "")
        case .custom(let message):
            return message
        }
    }
}

class LoadingManager: ObservableObject {
    static let shared = LoadingManager()
    
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var loadingType: LoadingType = .processing
    
    private init() {}
    
    func show(_ type: LoadingType = .processing) {
        isLoading = true
        loadingType = type
    }
    
    func hide() {
        isLoading = false
    }
} 
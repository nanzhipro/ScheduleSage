import SwiftUI

class PopoverViewModel: ObservableObject {
    @Published var showEventList: Bool = false
    
    func resetState() {
        showEventList = false
    }
} 
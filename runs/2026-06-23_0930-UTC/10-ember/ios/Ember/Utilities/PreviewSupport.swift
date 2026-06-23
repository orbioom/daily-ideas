import SwiftUI
import SwiftData

extension View {
    /// Attaches a seeded in-memory model container for SwiftUI previews. If the
    /// preview sandbox can't build a store, the view is returned unchanged so the
    /// preview still renders (without data) instead of failing.
    @MainActor
    @ViewBuilder
    func previewModelContainer() -> some View {
        if let container = PersistenceController.previewContainer() {
            self.modelContainer(container)
        } else {
            self
        }
    }
}

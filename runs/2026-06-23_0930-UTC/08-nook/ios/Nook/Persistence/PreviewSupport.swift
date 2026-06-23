import SwiftUI
import SwiftData

/// Helpers to attach a seeded in-memory container to SwiftUI previews without
/// force-unwrapping. If a container cannot be created, a calm fallback view is
/// shown instead.
extension View {
    @MainActor
    func previewModelContainer() -> some View {
        if let container = PersistenceController.previewContainer() {
            return AnyView(self.modelContainer(container))
        } else {
            return AnyView(Text("Preview unavailable").foregroundStyle(Theme.textSecondary))
        }
    }
}

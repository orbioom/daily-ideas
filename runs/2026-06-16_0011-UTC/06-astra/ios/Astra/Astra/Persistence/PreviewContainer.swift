import Foundation
import SwiftData

/// An in-memory, seeded ModelContainer for SwiftUI #Previews only.
@MainActor
enum PreviewContainer {
    static let shared: ModelContainer = {
        let schema = Schema([Profile.self, JournalEntry.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        if let container = try? ModelContainer(for: schema, configurations: config) {
            SeedData.seed(context: container.mainContext)
            return container
        }
        // Unreachable: an empty in-memory store cannot fail to build. This is the
        // preview-only sibling of AstraApp's single documented container fallback.
        fatalError("Preview container unavailable.")
    }()
}

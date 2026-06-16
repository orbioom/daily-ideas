import Foundation
import SwiftData

/// An in-memory, pre-seeded container for SwiftUI #Previews.
@MainActor
enum PreviewContainer {
    static let shared: ModelContainer = {
        let schema = Schema([Title.self, DiaryEntry.self, Tag.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        // An empty in-memory store cannot fail; fall back to a tiny config if it ever did.
        let container = (try? ModelContainer(for: schema, configurations: config))
            ?? (try? ModelContainer(for: schema))
        guard let container else {
            // Unreachable: an empty in-memory store cannot fail to build.
            fatalError("Unable to build preview container.")
        }
        SeedData.loadSample(into: container.mainContext)
        return container
    }()

    /// An empty in-memory container (for empty-state previews).
    static let empty: ModelContainer = {
        let schema = Schema([Title.self, DiaryEntry.self, Tag.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = (try? ModelContainer(for: schema, configurations: config))
            ?? (try? ModelContainer(for: schema))
        guard let container else {
            // Unreachable: an empty in-memory store cannot fail to build.
            fatalError("Unable to build empty preview container.")
        }
        return container
    }()
}

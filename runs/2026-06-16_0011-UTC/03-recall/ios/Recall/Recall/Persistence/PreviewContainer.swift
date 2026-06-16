import Foundation
import SwiftData

/// An in-memory, seeded ModelContainer for SwiftUI #Previews.
@MainActor
enum PreviewContainer {
    static let shared: ModelContainer = make()

    private static func make() -> ModelContainer {
        let schema = Schema([Deck.self, Card.self, ReviewLog.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        if let container = try? ModelContainer(for: schema, configurations: config) {
            SeedData.seed(context: container.mainContext)
            return container
        }
        // Previews-only fallback: a bare in-memory container with no seed data.
        // The schema is small and stored in memory, so this path is effectively unreachable;
        // the app target's RecallApp owns the single documented production fallback.
        return RecallApp.makeInMemoryContainer(schema: schema, configuration: config)
    }

    /// The first deck in the seeded preview store (for deck-scoped previews).
    static func firstDeck() -> Deck? {
        let descriptor = FetchDescriptor<Deck>(sortBy: [SortDescriptor(\.createdDate)])
        return (try? shared.mainContext.fetch(descriptor))?.first
    }
}

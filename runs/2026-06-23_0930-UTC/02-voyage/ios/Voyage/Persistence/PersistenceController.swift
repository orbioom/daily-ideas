import Foundation
import SwiftData

/// Builds the shared `ModelContainer` and seeds first-run data.
///
/// Container creation can theoretically fail (e.g. corrupt store). Rather than
/// trapping, `makeContainer` returns an optional and the app shell renders a
/// calm recoverable error screen when it is `nil`.
enum PersistenceController {

    static let schema = Schema([
        Deck.self,
        Phrase.self,
        ReviewState.self,
        AppSettings.self
    ])

    /// Production container backed by disk, with an in-memory fallback.
    /// Returns `nil` only if SwiftData cannot build any container at all.
    @MainActor
    static func makeContainer() -> ModelContainer? {
        // 1. Try the on-disk store.
        if let disk = try? ModelContainer(
            for: schema,
            configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)]
        ) {
            seedIfNeeded(disk.mainContext)
            return disk
        }
        // 2. Fall back to an in-memory store for this session.
        if let memory = try? ModelContainer(
            for: schema,
            configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)]
        ) {
            seedIfNeeded(memory.mainContext)
            return memory
        }
        // 3. Could not build a container; caller shows an error state.
        return nil
    }

    /// In-memory preview container with seeded data.
    @MainActor
    static func previewContainer() -> ModelContainer? {
        guard let container = try? ModelContainer(
            for: schema,
            configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)]
        ) else { return nil }
        SeedData.seed(into: container.mainContext)
        ensureSettings(container.mainContext)
        return container
    }

    /// Seed decks and a settings row only the first time the store is empty.
    @MainActor
    static func seedIfNeeded(_ context: ModelContext) {
        let deckCount = (try? context.fetchCount(FetchDescriptor<Deck>())) ?? 0
        if deckCount == 0 {
            SeedData.seed(into: context)
        }
        ensureSettings(context)
        try? context.save()
    }

    /// Guarantee exactly one `AppSettings` row exists.
    static func ensureSettings(_ context: ModelContext) {
        let count = (try? context.fetchCount(FetchDescriptor<AppSettings>())) ?? 0
        if count == 0 {
            context.insert(AppSettings())
        }
    }
}

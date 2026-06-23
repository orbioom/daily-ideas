import Foundation
import SwiftData

/// Builds the shared SwiftData container and provides a lightweight in-memory
/// container for previews.
enum PersistenceController {
    static let schema = Schema([
        Recipe.self,
        Ingredient.self,
        PlannedMeal.self,
        GroceryItem.self,
        PantryStaple.self,
        AppSettings.self
    ])

    static func makeContainer(inMemory: Bool = false) -> ModelContainer {
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            // Fall back to a fresh in-memory store so the app still launches
            // rather than crashing if the on-disk store is incompatible.
            let fallback = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            // This second attempt is extremely unlikely to fail; if it does we
            // have no store to run against, so we surface a clear message.
            guard let container = try? ModelContainer(for: schema, configurations: [fallback]) else {
                fatalError("Suppr could not initialise its data store.")
            }
            return container
        }
    }

    /// Fetches the singleton settings record, creating it if needed.
    @MainActor
    static func settings(in context: ModelContext) -> AppSettings {
        if let existing = try? context.fetch(FetchDescriptor<AppSettings>()).first {
            return existing
        }
        let fresh = AppSettings()
        context.insert(fresh)
        try? context.save()
        return fresh
    }

    /// Preview container pre-loaded with seed data.
    @MainActor
    static var preview: ModelContainer = {
        let container = makeContainer(inMemory: true)
        SeedData.loadIfNeeded(into: container.mainContext)
        return container
    }()
}

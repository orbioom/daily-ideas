import Foundation
import SwiftData

/// Builds the shared model container. Falls back to an in-memory store if the
/// on-disk store cannot be opened, so the app never crashes on launch.
enum PersistenceController {
    static let schema = Schema([
        Room.self,
        Appliance.self,
        MaintenanceTask.self,
        ServiceRecord.self,
        AppSettings.self
    ])

    /// Builds the container, returning nil only if both the on-disk and the
    /// in-memory stores fail to open. Callers surface a calm error instead of
    /// crashing.
    static func makeContainer(inMemory: Bool = false) -> ModelContainer? {
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        if let container = try? ModelContainer(for: schema, configurations: [config]) {
            return container
        }
        // Recoverable fallback: never fatalError on a user path.
        let memory = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try? ModelContainer(for: schema, configurations: [memory])
    }

    /// In-memory container preloaded with seed data, for SwiftUI previews.
    @MainActor
    static func previewContainer() -> ModelContainer? {
        guard let container = makeContainer(inMemory: true) else { return nil }
        SeedData.seedIfNeeded(context: container.mainContext)
        return container
    }
}

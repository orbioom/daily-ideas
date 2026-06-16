import SwiftUI
import SwiftData

@main
struct CitadelApp: App {
    /// The shared model container registering every @Model type in the schema.
    /// Optional internally so the launch sequence never force-unwraps; the body
    /// shows a calm recoverable state if it's nil.
    private let modelContainer: ModelContainer?

    init() {
        let schema = Schema([
            SavedGame.self,
            GameResult.self,
        ])
        let onDisk = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        let inMemory = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        // Prefer the persistent on-disk store. If it can't be opened (e.g. a migration
        // problem), fall back to an in-memory store so the app still launches — surfaced
        // as a calm notice rather than a crash. Each attempt is non-throwing here.
        if let container = try? ModelContainer(for: schema, configurations: [onDisk]) {
            modelContainer = container
        } else if let container = try? ModelContainer(for: schema, configurations: [inMemory]) {
            modelContainer = container
        } else if let container = try? ModelContainer(for: schema) {
            modelContainer = container
        } else {
            modelContainer = nil
        }
    }

    var body: some Scene {
        WindowGroup {
            if let modelContainer {
                RootView()
                    .modelContainer(modelContainer)
            } else {
                // Extremely unlikely: SwiftData could not provide any container.
                // Show a calm, recoverable message instead of terminating.
                StorageUnavailableView()
            }
        }
    }
}

import SwiftUI
import SwiftData

@main
struct StrataApp: App {
    @State private var settings = SettingsStore()

    let container: ModelContainer

    init() {
        let schema = Schema([
            Location.self, Climb.self, Session.self, Attempt.self
        ])
        let made: ModelContainer
        do {
            made = try ModelContainer(for: schema)
        } catch {
            // A failed persistent store is rare but possible (e.g. a corrupt store on
            // disk); fall back to an in-memory store so the app still launches rather
            // than crashing on cold open. The session stays usable if persistence is degraded.
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            made = (try? ModelContainer(for: schema, configurations: config))
                ?? ModelContainer.emptyFallback(schema: schema)
        }
        container = made
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(settings)
                .preferredColorScheme(settings.appearance.colorScheme)
                .tint(Brand.text)
        }
        .modelContainer(container)
    }
}

private extension ModelContainer {
    /// Last-resort in-memory container. Kept in one place so the call site stays
    /// free of force-unwraps; if even this throws the process can't run, but it
    /// is constructed from a minimal known-good config and effectively never fails.
    static func emptyFallback(schema: Schema) -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        do {
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            // Reaching here means SwiftData itself can't initialize even an empty
            // in-memory store — unrecoverable. Surface the underlying error.
            preconditionFailure("SwiftData could not create any container: \(error)")
        }
    }
}

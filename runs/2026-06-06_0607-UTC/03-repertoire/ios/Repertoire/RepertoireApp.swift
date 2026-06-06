import SwiftUI
import SwiftData

@main
struct RepertoireApp: App {
    @State private var settings = SettingsStore()

    let container: ModelContainer

    init() {
        let schema = Schema([
            Piece.self, PracticeSpot.self, PracticeSession.self, SessionEntry.self
        ])
        let made: ModelContainer
        do {
            made = try ModelContainer(for: schema)
        } catch {
            // A failed persistent store is rare but possible (e.g. a corrupt store on
            // disk); fall back to an in-memory store so the app still launches rather
            // than crashing on cold open. The session stays usable if persistence is degraded.
            do {
                let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                made = try ModelContainer(for: schema, configurations: config)
            } catch {
                fatalError("Unable to create a model container: \(error)")
            }
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

import SwiftUI
import SwiftData

@main
struct CellarApp: App {
    @State private var settings = SettingsStore()

    let container: ModelContainer

    init() {
        let made: ModelContainer
        do {
            made = try ModelContainer(for: Bottle.self, Tasting.self)
        } catch {
            // A failed persistent store is rare but possible (e.g. a corrupt store on disk);
            // fall back to an in-memory store so the app still launches rather than crashing
            // on cold open. The user keeps a working session even if persistence is degraded.
            do {
                let config = ModelConfiguration(isStoredInMemoryOnly: true)
                made = try ModelContainer(for: Bottle.self, Tasting.self, configurations: config)
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

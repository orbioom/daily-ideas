import SwiftUI
import SwiftData

@main
struct LuminaApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: Affirmation.self, DayLog.self)
        } catch {
            // A failed store is unrecoverable at launch; fall back to in-memory
            // so the app still opens rather than crashing the user out.
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            container = try! ModelContainer(for: Affirmation.self, DayLog.self, configurations: config)
        }
        Seeder.seedIfNeeded(container.mainContext)
        Haptics.enabled = UserDefaults.standard.object(forKey: "haptics") as? Bool ?? true
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}

import SwiftUI
import SwiftData

@main
struct PitchApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: Tuning.self, MetronomePreset.self)
        } catch {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            container = try! ModelContainer(for: Tuning.self, MetronomePreset.self, configurations: config)
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

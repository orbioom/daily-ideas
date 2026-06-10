import SwiftUI
import SwiftData

@main
struct LexicApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: WordGame.self)
        } catch {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            container = try! ModelContainer(for: WordGame.self, configurations: config)
        }
        Haptics.enabled = UserDefaults.standard.object(forKey: "haptics") as? Bool ?? true
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}

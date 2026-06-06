import SwiftUI
import SwiftData

@main
struct SkeinApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: Project.self, Counter.self, StashYarn.self)
        } catch {
            // A fresh on-device store should always succeed; if not, fall back
            // to an in-memory store so the app still launches rather than crashing.
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            container = try! ModelContainer(for: Project.self, Counter.self, StashYarn.self,
                                            configurations: config)
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}

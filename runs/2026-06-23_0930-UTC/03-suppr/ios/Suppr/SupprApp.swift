import SwiftUI
import SwiftData

@main
struct SupprApp: App {
    let container: ModelContainer

    init() {
        container = PersistenceController.makeContainer()
        // Seed once on first launch.
        SeedData.loadIfNeeded(into: container.mainContext)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}

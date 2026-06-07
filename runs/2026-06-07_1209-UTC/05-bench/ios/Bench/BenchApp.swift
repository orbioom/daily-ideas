import SwiftUI
import SwiftData

@main
struct BenchApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: SavedCalc.self, Component.self)
        } catch {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            container = try! ModelContainer(for: SavedCalc.self, Component.self, configurations: config)
        }
    }

    var body: some Scene {
        WindowGroup { RootView() }
            .modelContainer(container)
    }
}

import SwiftUI
import SwiftData

@main
struct FathomApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: Dive.self, DiveSite.self)
        } catch {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            container = try! ModelContainer(for: Dive.self, DiveSite.self, configurations: config)
        }
    }

    var body: some Scene {
        WindowGroup { RootView() }
            .modelContainer(container)
    }
}

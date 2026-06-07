import SwiftUI
import SwiftData

@main
struct ZenithApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: Telescope.self, Eyepiece.self, Observation.self)
        } catch {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            container = try! ModelContainer(for: Telescope.self, Eyepiece.self, Observation.self,
                                            configurations: config)
        }
    }

    var body: some Scene {
        WindowGroup { RootView() }
            .modelContainer(container)
    }
}

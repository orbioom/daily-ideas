import SwiftUI
import SwiftData

@main
struct PlumeApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: Species.self, Sighting.self, Trip.self)
        } catch {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            container = try! ModelContainer(for: Species.self, Sighting.self, Trip.self,
                                            configurations: config)
        }
    }

    var body: some Scene {
        WindowGroup { RootView() }
            .modelContainer(container)
    }
}

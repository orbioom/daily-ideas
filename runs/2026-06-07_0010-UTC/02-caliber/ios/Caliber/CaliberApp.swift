import SwiftUI
import SwiftData

@main
struct CaliberApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: Watch.self, WatchMeasurement.self)
        } catch {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            container = try! ModelContainer(for: Watch.self, WatchMeasurement.self,
                                            configurations: config)
        }
    }

    var body: some Scene {
        WindowGroup { RootView() }
            .modelContainer(container)
    }
}

import SwiftUI
import SwiftData

@main
struct BeaconApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: Activation.self, QSO.self)
        } catch {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            // In-memory fallback keeps the app usable even if the store can't open.
            container = try! ModelContainer(for: Activation.self, QSO.self, configurations: config)
        }
    }

    var body: some Scene {
        WindowGroup { RootView() }
            .modelContainer(container)
    }
}

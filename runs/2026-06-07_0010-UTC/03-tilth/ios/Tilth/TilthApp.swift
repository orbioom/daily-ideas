import SwiftUI
import SwiftData

@main
struct TilthApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: Crop.self, Bed.self, Planting.self)
        } catch {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            container = try! ModelContainer(for: Crop.self, Bed.self, Planting.self,
                                            configurations: config)
        }
    }

    var body: some Scene {
        WindowGroup { RootView() }
            .modelContainer(container)
    }
}

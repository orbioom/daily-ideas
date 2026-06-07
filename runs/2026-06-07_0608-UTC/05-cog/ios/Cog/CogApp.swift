import SwiftUI
import SwiftData

@main
struct CogApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: Bike.self, Component.self, Ride.self, ServiceRecord.self)
        } catch {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            container = try! ModelContainer(for: Bike.self, Component.self, Ride.self, ServiceRecord.self,
                                            configurations: config)
        }
    }

    var body: some Scene {
        WindowGroup { RootView() }
            .modelContainer(container)
    }
}

import SwiftUI
import SwiftData

@main
struct VerdantApp: App {
    let container: ModelContainer

    init() {
        let schema = Schema([Plant.self, CareEvent.self, Room.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        if let c = try? ModelContainer(for: schema, configurations: [config]) {
            container = c
        } else {
            container = try! ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)])
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}

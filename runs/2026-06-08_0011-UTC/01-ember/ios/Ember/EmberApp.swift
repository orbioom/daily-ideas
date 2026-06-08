import SwiftUI
import SwiftData

@main
struct EmberApp: App {
    let container: ModelContainer

    init() {
        let schema = Schema([Fast.self, Plan.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        if let c = try? ModelContainer(for: schema, configurations: config) {
            container = c
        } else {
            container = try! ModelContainer(for: schema,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        }
    }

    var body: some Scene {
        WindowGroup { RootView() }
            .modelContainer(container)
    }
}

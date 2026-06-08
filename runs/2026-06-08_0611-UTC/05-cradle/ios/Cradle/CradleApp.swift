import SwiftUI
import SwiftData

@main
struct CradleApp: App {
    let container: ModelContainer

    init() {
        let schema = Schema([Baby.self, CareEvent.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        if let c = try? ModelContainer(for: schema, configurations: [config]) {
            container = c
        } else {
            // Safe fallback to in-memory store
            let memConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            container = try! ModelContainer(for: schema, configurations: [memConfig])
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}

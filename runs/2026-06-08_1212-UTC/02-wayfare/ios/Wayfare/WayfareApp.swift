import SwiftUI
import SwiftData

@main
struct WayfareApp: App {
    let container: ModelContainer

    init() {
        let schema = Schema([Trip.self, Activity.self, Lodging.self, PackingItem.self, Expense.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        if let c = try? ModelContainer(for: schema, configurations: config) {
            container = c
        } else {
            let mem = ModelConfiguration(isStoredInMemoryOnly: true)
            container = (try? ModelContainer(for: schema, configurations: mem))
                ?? { fatalError("Unable to create in-memory ModelContainer") }()
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}

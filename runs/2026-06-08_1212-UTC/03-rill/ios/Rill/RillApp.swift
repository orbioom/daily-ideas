import SwiftUI
import SwiftData

@main
struct RillApp: App {
    let container: ModelContainer

    init() {
        GoalSettings.registerDefaults()
        let schema = Schema([DrinkType.self, DrinkLog.self])
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

import SwiftUI
import SwiftData

@main
struct DuetApp: App {
    let container: ModelContainer

    init() {
        let schema = Schema([Answer.self, Memory.self, CheckIn.self, IdeaMark.self, Occasion.self])
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
        WindowGroup { RootView() }
            .modelContainer(container)
    }
}

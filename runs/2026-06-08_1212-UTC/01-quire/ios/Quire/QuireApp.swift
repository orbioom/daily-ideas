import SwiftUI
import SwiftData

@main
struct QuireApp: App {
    let container: ModelContainer

    init() {
        let schema = Schema([JournalEntry.self, Tag.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        if let c = try? ModelContainer(for: schema, configurations: config) {
            container = c
        } else {
            // Fall back to an in-memory store so the app still launches rather
            // than crashing if the on-disk store can't be opened.
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

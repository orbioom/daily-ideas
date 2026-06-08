import SwiftUI
import SwiftData

@main
struct AnewApp: App {

    let container: ModelContainer

    init() {
        let schema = Schema([Quit.self, Relapse.self, CheckIn.self])
        let config = ModelConfiguration("anew", schema: schema)
        if let c = try? ModelContainer(for: schema, configurations: config) {
            container = c
        } else {
            container = try! ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}

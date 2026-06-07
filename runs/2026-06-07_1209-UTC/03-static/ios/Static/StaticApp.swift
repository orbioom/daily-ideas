import SwiftUI
import SwiftData

@main
struct StaticApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: ApneaTable.self, ApneaSession.self)
        } catch {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            container = try! ModelContainer(for: ApneaTable.self, ApneaSession.self, configurations: config)
        }
    }

    var body: some Scene {
        WindowGroup { RootView() }
            .modelContainer(container)
    }
}

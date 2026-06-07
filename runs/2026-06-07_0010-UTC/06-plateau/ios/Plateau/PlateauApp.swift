import SwiftUI
import SwiftData

@main
struct PlateauApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: Cook.self)
        } catch {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            container = try! ModelContainer(for: Cook.self, configurations: config)
        }
    }

    var body: some Scene {
        WindowGroup { RootView() }
            .modelContainer(container)
    }
}

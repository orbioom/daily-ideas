import SwiftUI
import SwiftData

@main
struct KerfApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: Project.self, Part.self, StockBoard.self)
        } catch {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            container = try! ModelContainer(for: Project.self, Part.self, StockBoard.self, configurations: config)
        }
    }

    var body: some Scene {
        WindowGroup { RootView() }
            .modelContainer(container)
    }
}

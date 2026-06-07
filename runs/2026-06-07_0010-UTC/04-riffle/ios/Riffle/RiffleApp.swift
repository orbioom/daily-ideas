import SwiftUI
import SwiftData

@main
struct RiffleApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: Pattern.self, Material.self, Catch.self)
        } catch {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            container = try! ModelContainer(for: Pattern.self, Material.self, Catch.self,
                                            configurations: config)
        }
    }

    var body: some Scene {
        WindowGroup { RootView() }
            .modelContainer(container)
    }
}

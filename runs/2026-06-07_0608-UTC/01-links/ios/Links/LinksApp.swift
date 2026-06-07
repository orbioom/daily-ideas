import SwiftUI
import SwiftData

@main
struct LinksApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: Course.self, Tee.self, Round.self)
        } catch {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            container = try! ModelContainer(for: Course.self, Tee.self, Round.self,
                                            configurations: config)
        }
    }

    var body: some Scene {
        WindowGroup { RootView() }
            .modelContainer(container)
    }
}

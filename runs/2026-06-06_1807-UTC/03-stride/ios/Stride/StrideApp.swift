import SwiftUI
import SwiftData

@main
struct StrideApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: Run.self)
        } catch {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            container = try! ModelContainer(for: Run.self, configurations: config)
        }
    }

    var body: some Scene {
        WindowGroup { RootView() }
            .modelContainer(container)
    }
}

import SwiftUI
import SwiftData

@main
struct CurfewApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: CaffeineSource.self, Intake.self)
        } catch {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            container = try! ModelContainer(for: CaffeineSource.self, Intake.self, configurations: config)
        }
    }

    var body: some Scene {
        WindowGroup { RootView() }
            .modelContainer(container)
    }
}

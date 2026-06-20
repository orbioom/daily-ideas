import SwiftUI
import SwiftData

@main
struct HaloApp: SwiftUI.App {
    let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try ModelContainer(
                for: HaloSession.self, HaloSettings.self
            )
        } catch {
            fatalError("[HaloApp] Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
        }
    }
}

import SwiftUI
import SwiftData

@main
struct PebbleApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [PebbleStats.self, PebbleSettings.self, PebbleOnboarding.self])
    }
}

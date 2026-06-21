import SwiftUI
import SwiftData

@main
struct DraughtsApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [DraughtsStats.self, DraughtsSettings.self, DraughtsOnboarding.self])
    }
}

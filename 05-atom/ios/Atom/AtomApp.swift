import SwiftUI
import SwiftData

@main
struct AtomApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [AtomProgress.self, AtomPrefs.self, AtomOnboarding.self])
    }
}

import SwiftUI
import SwiftData

@main
struct PegApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [PegStats.self, PegSettings.self, PegOnboarding.self])
    }
}

import SwiftUI
import SwiftData

@main
struct GlowApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [SavedProduct.self, GlowSettings.self])
    }
}

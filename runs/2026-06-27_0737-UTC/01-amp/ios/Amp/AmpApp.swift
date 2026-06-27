import SwiftUI
import SwiftData

@main
struct AmpApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(AmpContainer.shared)
        }
    }
}

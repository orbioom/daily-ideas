import SwiftUI
import SwiftData

@main
struct OrbApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: OrbResult.self)
        }
    }
}

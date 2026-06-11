import SwiftUI
import SwiftData

@main
struct NimbleApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [GameSession.self, DailyResult.self])
    }
}

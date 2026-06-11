import SwiftUI
import SwiftData

@main
struct WeaveApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: PuzzleAttempt.self)
    }
}

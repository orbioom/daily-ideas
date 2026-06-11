import SwiftUI
import SwiftData

@main
struct PixApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: PuzzleProgress.self)
    }
}

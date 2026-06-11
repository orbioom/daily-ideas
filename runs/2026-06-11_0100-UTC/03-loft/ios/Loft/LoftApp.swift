import SwiftUI
import SwiftData

@main
struct LoftApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [VisionBoard.self, BoardItem.self, Goal.self, Milestone.self])
    }
}

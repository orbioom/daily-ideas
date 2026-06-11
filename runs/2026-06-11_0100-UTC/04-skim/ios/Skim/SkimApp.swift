import SwiftUI
import SwiftData

@main
struct SkimApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [Article.self, ReadingSession.self])
    }
}

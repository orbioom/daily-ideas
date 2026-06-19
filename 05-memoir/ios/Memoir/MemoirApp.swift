import SwiftUI
import SwiftData

@main
struct MemoirApp: App {
    var body: some Scene {
        WindowGroup {
            MemoirContentView()
        }
        .modelContainer(for: [StoryEntry.self, WritingPrompt.self])
    }
}

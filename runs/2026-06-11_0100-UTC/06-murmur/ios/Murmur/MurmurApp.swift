import SwiftUI
import SwiftData

@main
struct MurmurApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [VoiceEntry.self, JournalTag.self])
    }
}

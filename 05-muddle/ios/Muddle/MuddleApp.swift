import SwiftUI
import SwiftData

@main
struct MuddleApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [DailyResult.self, PackProgress.self])
    }
}

import SwiftUI
import SwiftData

@main
struct RhymeApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [FavoriteWord.self, LyricEntry.self])
    }
}

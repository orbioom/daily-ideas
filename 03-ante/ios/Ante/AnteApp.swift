import SwiftUI
import SwiftData

@main
struct AnteApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [GameRecord.self, AppPreferences.self])
    }
}

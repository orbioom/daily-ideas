import SwiftUI
import SwiftData

@main
struct ScriptApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [ScriptProject.self, ScriptSettings.self])
    }
}

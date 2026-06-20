import SwiftUI
import SwiftData

@main
struct CanopyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: [EmissionEntry.self, CanopySettings.self])
        }
    }
}

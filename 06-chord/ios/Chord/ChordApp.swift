import SwiftUI
import SwiftData

@main
struct ChordApp: App {
    var body: some Scene {
        WindowGroup {
            ChordContentView()
        }
        .modelContainer(for: [Progression.self, ChordSlot.self])
    }
}

import SwiftUI
import SwiftData

@main
struct StrokeApp: App {
    var body: some Scene {
        WindowGroup {
            StrokeContentView()
        }
        .modelContainer(StrokeContainer.shared)
    }
}

import SwiftUI
import SwiftData

@main
struct SparApp: App {
    var body: some Scene {
        WindowGroup {
            SparContentView()
        }
        .modelContainer(SparContainer.shared)
    }
}

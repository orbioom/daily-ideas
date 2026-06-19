import SwiftUI
import SwiftData

@main
struct SparkApp: App {
    var body: some Scene {
        WindowGroup {
            SparkContentView()
                .modelContainer(for: [FocusTask.self, FocusSession.self])
        }
    }
}

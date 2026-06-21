import SwiftUI
import SwiftData

@main
struct PushApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            PushRecord.self,
            PushPrefs.self,
            PushDailyResult.self,
            PushOnboarding.self
        ])
    }
}

import SwiftUI
import SwiftData

@main
struct SlideApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [SlideRecord.self, SlidePrefs.self, SlideDailyResult.self, SlideOnboarding.self])
    }
}

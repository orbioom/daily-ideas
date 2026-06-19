import SwiftUI
import SwiftData

@main
struct ScribeApp: App {
    var body: some Scene {
        WindowGroup {
            ScribeRootView()
        }
        .modelContainer(for: [GameRecord.self, ScribePrefs.self])
    }
}

struct ScribeRootView: View {
    @Query private var prefs: [ScribePrefs]
    var body: some View {
        if prefs.first?.hasSeenOnboarding == true {
            ContentView()
        } else {
            ScribeOnboardingView()
        }
    }
}

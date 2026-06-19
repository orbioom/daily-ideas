import SwiftUI
import SwiftData

@main
struct StampApp: App {
    var body: some Scene {
        WindowGroup {
            StampRootView()
        }
        .modelContainer(for: [SavedSticker.self, StampPrefs.self])
    }
}

struct StampRootView: View {
    @Query private var prefs: [StampPrefs]
    var body: some View {
        if prefs.first?.hasSeenOnboarding == true {
            ContentView()
        } else {
            StampOnboardingView()
        }
    }
}

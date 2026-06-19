import SwiftUI
import SwiftData

@main
struct StippleApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [SceneProgress.self, StipplePrefs.self])
    }
}

struct RootView: View {
    @Query private var prefs: [StipplePrefs]
    var body: some View {
        if prefs.first?.hasSeenOnboarding == true {
            ContentView()
        } else {
            OnboardingView()
        }
    }
}

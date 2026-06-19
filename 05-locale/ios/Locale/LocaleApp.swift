import SwiftUI
import SwiftData

@main
struct LocaleApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [FavoritePhrase.self, LocalePrefs.self])
    }
}

struct RootView: View {
    @Query private var prefs: [LocalePrefs]
    var body: some View {
        if prefs.first?.hasSeenOnboarding == true {
            ContentView()
        } else {
            OnboardingView()
        }
    }
}

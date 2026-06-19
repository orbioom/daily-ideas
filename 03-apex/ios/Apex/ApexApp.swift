import SwiftUI
import SwiftData

@main
struct ApexApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [GameResult.self, AppPreferences.self])
    }
}

struct RootView: View {
    @Query private var prefs: [AppPreferences]
    private var pref: AppPreferences? { prefs.first }

    var body: some View {
        if pref?.hasSeenOnboarding == true {
            ContentView()
        } else {
            OnboardingView()
        }
    }
}

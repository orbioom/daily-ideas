import SwiftUI
import SwiftData

@main
struct GomokuApp: App {
    var body: some Scene {
        WindowGroup {
            ContentRootView()
        }
        .modelContainer(for: [GomokuResult.self, GomokuPrefs.self])
    }
}

struct ContentRootView: View {
    @Query private var prefs: [GomokuPrefs]

    var body: some View {
        if let p = prefs.first, p.onboardingDone {
            MainTabView()
        } else {
            OnboardingView()
        }
    }
}

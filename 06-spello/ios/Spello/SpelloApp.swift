import SwiftUI
import SwiftData

@main
struct SpelloApp: App {
    var body: some Scene {
        WindowGroup { SpelloRoot() }
            .modelContainer(for: [SpelloProfile.self, SpelloSession.self, SpelloPrefs.self])
    }
}

struct SpelloRoot: View {
    @Query private var prefs: [SpelloPrefs]
    var body: some View {
        if let p = prefs.first, p.onboardingDone {
            SpelloTabView()
        } else {
            SpelloOnboarding()
        }
    }
}

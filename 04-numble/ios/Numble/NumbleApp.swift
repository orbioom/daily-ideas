import SwiftUI
import SwiftData

@main
struct NumbleApp: App {
    var body: some Scene {
        WindowGroup { NumbleRoot() }
            .modelContainer(for: [NumbleResult.self, NumblePrefs.self])
    }
}

struct NumbleRoot: View {
    @Query private var prefs: [NumblePrefs]
    var body: some View {
        if let p = prefs.first, p.onboardingDone {
            NumbleTabView()
        } else {
            NumbleOnboarding()
        }
    }
}

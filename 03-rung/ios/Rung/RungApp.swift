import SwiftUI
import SwiftData

@main
struct RungApp: App {
    var body: some Scene {
        WindowGroup { RungRoot() }
            .modelContainer(for: [RungResult.self, RungPrefs.self])
    }
}

struct RungRoot: View {
    @Query private var prefs: [RungPrefs]
    var body: some View {
        if let p = prefs.first, p.onboardingDone {
            RungTabView()
        } else {
            RungOnboarding()
        }
    }
}

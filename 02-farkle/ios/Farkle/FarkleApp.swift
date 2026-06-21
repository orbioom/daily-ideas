import SwiftUI
import SwiftData

@main
struct FarkleApp: App {
    var body: some Scene {
        WindowGroup {
            FarkleRoot()
        }
        .modelContainer(for: [FarkleGame.self, FarklePrefs.self])
    }
}

struct FarkleRoot: View {
    @Query private var prefs: [FarklePrefs]
    var body: some View {
        if let p = prefs.first, p.onboardingDone {
            FarkleTabView()
        } else {
            FarkleOnboarding()
        }
    }
}

import SwiftUI
import SwiftData

@main
struct SalvoApp: App {
    var body: some Scene {
        WindowGroup { SalvoRoot() }
            .modelContainer(for: [SalvoResult.self, SalvoPrefs.self])
    }
}

struct SalvoRoot: View {
    @Query private var prefs: [SalvoPrefs]
    var body: some View {
        if let p = prefs.first, p.onboardingDone {
            SalvoTabView()
        } else {
            SalvoOnboarding()
        }
    }
}

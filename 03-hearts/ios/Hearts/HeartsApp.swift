import SwiftUI
import SwiftData

@main
struct HeartsApp: App {
    var body: some Scene {
        WindowGroup {
            HeartsRootView()
        }
        .modelContainer(for: HeartsGameRecord.self)
    }
}

struct HeartsRootView: View {
    @AppStorage("heartsHasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some View {
        if hasSeenOnboarding {
            HeartsContentView()
        } else {
            HeartsOnboardingView()
        }
    }
}

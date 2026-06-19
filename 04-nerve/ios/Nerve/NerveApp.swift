import SwiftUI
import SwiftData

@main
struct NerveApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [GameRecord.self, DailyResult.self])
    }
}

struct RootView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some View {
        if hasSeenOnboarding {
            ContentView()
        } else {
            OnboardingView()
        }
    }
}

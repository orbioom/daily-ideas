import SwiftUI
import SwiftData

@main
struct MistApp: App {
    var body: some Scene {
        WindowGroup {
            MistRootView()
        }
        .modelContainer(for: TherapySession.self)
    }
}

struct MistRootView: View {
    @AppStorage("mistHasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some View {
        if hasSeenOnboarding {
            ContentView()
        } else {
            MistOnboardingView()
        }
    }
}

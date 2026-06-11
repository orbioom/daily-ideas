import SwiftUI
import SwiftData

@main
struct TimberApp: App {
    @AppStorage("hasOnboarded") private var hasOnboarded = false

    var body: some Scene {
        WindowGroup {
            Group {
                if hasOnboarded {
                    RootView()
                } else {
                    OnboardingView()
                }
            }
        }
        .modelContainer(for: [NightSession.self, SnoreEpisode.self, SleepFactor.self])
    }
}

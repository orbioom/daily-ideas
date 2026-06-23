import SwiftUI
import SwiftData

@main
struct PackwiseApp: App {
    let container: ModelContainer
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    init() {
        let container = DataController.makeContainer()
        self.container = container
        // Seed sample data once, on the main context. App init runs on the main
        // thread, so we assume main-actor isolation for the seeding call.
        MainActor.assumeIsolated {
            DataController.seedIfNeeded(container.mainContext)
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    RootTabView()
                } else {
                    OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                }
            }
            .tint(Theme.primary)
        }
        .modelContainer(container)
    }
}

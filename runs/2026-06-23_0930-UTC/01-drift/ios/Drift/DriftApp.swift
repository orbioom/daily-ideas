import SwiftUI
import SwiftData

@main
struct DriftApp: App {
    /// Persisted onboarding flag — gates first-run flow.
    @AppStorage("hasOnboarded") private var hasOnboarded: Bool = false

    let container: ModelContainer

    init() {
        let container = PersistenceController.makeContainer()
        self.container = container
    }

    var body: some Scene {
        WindowGroup {
            RootView(hasOnboarded: $hasOnboarded)
                .task {
                    await MainActor.run {
                        PersistenceController.seedIfNeeded(container.mainContext)
                    }
                }
                .tint(Theme.accent)
        }
        .modelContainer(container)
    }
}

/// Switches between onboarding and the main tab experience.
struct RootView: View {
    @Binding var hasOnboarded: Bool

    var body: some View {
        Group {
            if hasOnboarded {
                MainTabView()
                    .transition(.opacity)
            } else {
                OnboardingView(hasOnboarded: $hasOnboarded)
                    .transition(.opacity)
            }
        }
    }
}

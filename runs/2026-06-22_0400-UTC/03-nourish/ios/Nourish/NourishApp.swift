import SwiftUI
import SwiftData

@main
struct NourishApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [FoodLogEntry.self, SymptomEntry.self, EliminationPhase.self, NourishSettings.self])
    }
}

struct RootView: View {
    @Query private var settings: [NourishSettings]
    @Environment(\.modelContext) private var context

    var body: some View {
        Group {
            if let s = settings.first, s.hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView()
                    .onAppear { ensureSettings() }
            }
        }
        .onAppear { ensureSettings() }
    }

    private func ensureSettings() {
        if settings.isEmpty { context.insert(NourishSettings()) }
    }
}

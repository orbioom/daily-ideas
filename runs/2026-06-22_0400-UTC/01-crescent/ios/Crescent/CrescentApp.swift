import SwiftUI
import SwiftData

@main
struct CrescentApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [MoonJournalEntry.self, RitualCompletion.self, CrescentSettings.self])
    }
}

struct RootView: View {
    @Query private var settings: [CrescentSettings]
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
        if settings.isEmpty {
            let s = CrescentSettings()
            context.insert(s)
        }
    }
}

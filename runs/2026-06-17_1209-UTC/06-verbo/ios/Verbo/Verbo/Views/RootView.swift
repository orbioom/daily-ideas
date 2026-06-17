import SwiftUI
import SwiftData

/// Switches between onboarding and the main tab bar; seeds data once.
struct RootView: View {
    @Environment(\.modelContext) private var context
    @AppStorage(Prefs.hasOnboarded) private var hasOnboarded = false

    var body: some View {
        Group {
            if hasOnboarded {
                MainTabView()
                    .task { SeedData.seedIfNeeded(context: context) }
            } else {
                OnboardingView()
            }
        }
    }
}

/// The main four-feature tab bar plus Settings.
struct MainTabView: View {
    var body: some View {
        TabView {
            PracticeScreen()
                .tabItem { Label("Practice", systemImage: "checkmark.circle") }

            VerbsScreen()
                .tabItem { Label("Verbs", systemImage: "text.book.closed") }

            TensesScreen()
                .tabItem { Label("Learn", systemImage: "graduationcap") }

            ProgressScreen()
                .tabItem { Label("Progress", systemImage: "chart.line.uptrend.xyaxis") }

            SettingsScreen()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}

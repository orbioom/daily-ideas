import SwiftUI
import SwiftData

/// Top-level switch between onboarding and the main tab bar. Seeds sample data on first appearance.
struct RootView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("hasOnboarded") private var hasOnboarded = false

    var body: some View {
        Group {
            if hasOnboarded {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .task {
            SeedData.seedIfNeeded(context: context)
        }
    }
}

/// The main TabView shown after onboarding.
struct MainTabView: View {
    var body: some View {
        TabView {
            GoalsScreen()
                .tabItem { Label("Goals", systemImage: "target") }

            AllocateScreen()
                .tabItem { Label("Allocate", systemImage: "square.split.2x2") }

            InsightsScreen()
                .tabItem { Label("Insights", systemImage: "chart.xyaxis.line") }

            SettingsScreen()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}

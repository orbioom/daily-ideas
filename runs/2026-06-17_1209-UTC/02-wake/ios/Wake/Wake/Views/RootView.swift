import SwiftUI
import SwiftData

/// Switches between onboarding and the main tab bar, and seeds data on first run.
struct RootView: View {
    @Environment(\.modelContext) private var context
    @AppStorage(PrefKey.hasOnboarded) private var hasOnboarded = false
    @AppStorage(PrefKey.didSeed) private var didSeed = false

    var body: some View {
        Group {
            if hasOnboarded {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .task {
            var seeded = didSeed
            SeedData.seedIfNeeded(context: context, didSeed: &seeded)
            didSeed = seeded
        }
    }
}

/// The four feature tabs plus Settings.
struct MainTabView: View {
    var body: some View {
        TabView {
            SwimScreen()
                .tabItem { Label("Swim", systemImage: "figure.pool.swim") }
            WorkoutsScreen()
                .tabItem { Label("Workouts", systemImage: "list.bullet.rectangle") }
            LogScreen()
                .tabItem { Label("Log", systemImage: "calendar") }
            StatsScreen()
                .tabItem { Label("Stats", systemImage: "chart.xyaxis.line") }
            SettingsScreen()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}

import SwiftUI
import SwiftData

/// Switches between onboarding and the main tab bar, and seeds data once.
struct RootView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @AppStorage("didSeed") private var didSeed = false

    var body: some View {
        Group {
            if hasOnboarded {
                MainTabView()
                    .task {
                        var seeded = didSeed
                        SeedData.seedIfNeeded(context: context, didSeed: &seeded)
                        didSeed = seeded
                    }
            } else {
                OnboardingView()
            }
        }
    }
}

/// The app's four feature screens plus Settings.
struct MainTabView: View {
    var body: some View {
        TabView {
            HomeScreen()
                .tabItem { Label("Home", systemImage: "house.fill") }

            TasksScreen()
                .tabItem { Label("Tasks", systemImage: "checklist") }

            ScheduleScreen()
                .tabItem { Label("Schedule", systemImage: "calendar") }

            InsightsScreen()
                .tabItem { Label("Insights", systemImage: "chart.bar.xaxis") }

            SettingsScreen()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}

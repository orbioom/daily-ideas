import SwiftUI
import SwiftData

/// Root: gates onboarding, hosts the main TabView, seeds sample data once.
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

/// The main tab bar.
struct MainTabView: View {
    var body: some View {
        TabView {
            TodayScreen()
                .tabItem { Label("Today", systemImage: "flame.fill") }

            ProgramsScreen()
                .tabItem { Label("Programs", systemImage: "square.grid.2x2.fill") }

            HistoryScreen()
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }

            ProgressScreen()
                .tabItem { Label("Progress", systemImage: "chart.xyaxis.line") }

            SettingsScreen()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}

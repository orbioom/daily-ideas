import SwiftUI
import SwiftData

@main
struct DripApp: App {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some Scene {
        WindowGroup {
            if hasSeenOnboarding {
                DripRootView()
            } else {
                DripOnboardingView(isComplete: $hasSeenOnboarding)
            }
        }
        .modelContainer(for: [DrinkEntry.self, DrinkGoal.self])
    }
}

struct DripRootView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem { Label("Today", systemImage: "drop.fill") }
                .tag(0)

            InsightsView()
                .tabItem { Label("Insights", systemImage: "chart.bar.fill") }
                .tag(1)

            HistoryView()
                .tabItem { Label("History", systemImage: "clock.fill") }
                .tag(2)

            GoalView()
                .tabItem { Label("Goal", systemImage: "target") }
                .tag(3)

            DripSettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
                .tag(4)
        }
        .tint(DripTheme.teal)
    }
}

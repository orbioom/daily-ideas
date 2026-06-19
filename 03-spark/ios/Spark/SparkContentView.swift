import SwiftUI

struct SparkContentView: View {
    @AppStorage(SparkSettings.onboardingDone) private var onboardingDone = false

    var body: some View {
        if !onboardingDone {
            SparkOnboardingView()
        } else {
            SparkTabView()
        }
    }
}

struct SparkTabView: View {
    var body: some View {
        TabView {
            FocusView()
                .tabItem { Label("Focus", systemImage: "bolt.fill") }

            TasksView()
                .tabItem { Label("Tasks", systemImage: "checklist") }

            SparkStatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar.fill") }

            SparkSettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
        }
        .tint(SparkTheme.electricBlue)
    }
}

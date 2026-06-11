import SwiftUI
import SwiftData

@main
struct ReelApp: App {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some Scene {
        WindowGroup {
            if hasSeenOnboarding {
                RootView()
            } else {
                OnboardingView(isComplete: $hasSeenOnboarding)
            }
        }
        .modelContainer(for: [MediaEntry.self, Season.self, Episode.self])
    }
}

struct RootView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            LibraryView()
                .tabItem { Label("Library", systemImage: "film.stack") }
                .tag(0)

            StatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar.fill") }
                .tag(1)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
                .tag(2)
        }
        .tint(Theme.gold)
    }
}

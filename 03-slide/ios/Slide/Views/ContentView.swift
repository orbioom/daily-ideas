import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var onboardings: [SlideOnboarding]

    var hasOnboarded: Bool { onboardings.first?.completed == true }

    var body: some View {
        if hasOnboarded {
            MainTabView()
        } else {
            OnboardingView()
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationStack { PuzzleView() }
                .tabItem { Label("Play", systemImage: "puzzlepiece.fill") }
            NavigationStack { DailyView() }
                .tabItem { Label("Daily", systemImage: "calendar") }
            NavigationStack { StatsView() }
                .tabItem { Label("Stats", systemImage: "chart.bar.fill") }
            NavigationStack { SettingsView() }
                .tabItem { Label("Settings", systemImage: "gear") }
        }
        .tint(SlideTheme.accent)
    }
}

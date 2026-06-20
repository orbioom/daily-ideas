import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("highestLevelReached") private var highestLevelReached = 1
    @State private var selectedTab = 0
    @State private var game = OrbGame()

    var body: some View {
        if !hasSeenOnboarding {
            OrbOnboardingView(hasSeenOnboarding: $hasSeenOnboarding)
        } else {
            TabView(selection: $selectedTab) {
                OrbGameView(game: game)
                    .tabItem {
                        Label("Play", systemImage: "circle.fill")
                    }
                    .tag(0)

                LevelSelectView(game: game, selectedTab: $selectedTab)
                    .tabItem {
                        Label("Levels", systemImage: "square.grid.3x3.fill")
                    }
                    .tag(1)

                OrbStatsView()
                    .tabItem {
                        Label("Stats", systemImage: "chart.bar.fill")
                    }
                    .tag(2)

                OrbSettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
                    .tag(3)
            }
            .tint(OrbTheme.accent)
            .preferredColorScheme(.dark)
        }
    }
}

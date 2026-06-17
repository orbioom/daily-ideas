import SwiftUI

/// The main five-tab experience: Play, Levels, Daily, Stats, Settings.
struct MainTabView: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        TabView {
            PlayHomeView()
                .tabItem { Label("Play", systemImage: "play.circle.fill") }

            LevelsView()
                .tabItem { Label("Levels", systemImage: "square.grid.2x2.fill") }

            DailyView()
                .tabItem { Label("Daily", systemImage: "calendar") }

            StatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar.fill") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(ConduitTheme.accent)
    }
}

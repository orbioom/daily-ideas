import SwiftUI

/// Top-level tab container. Home, Daily, Stats, Settings.
struct RootView: View {
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Play", systemImage: "square.grid.3x3.fill") }

            DailyView()
                .tabItem { Label("Daily", systemImage: "calendar") }

            StatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar.fill") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(Theme.accent)
    }
}

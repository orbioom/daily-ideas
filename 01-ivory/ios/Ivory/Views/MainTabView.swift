import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            GameView()
                .tabItem { Label("Play", systemImage: "circle.grid.2x2.fill") }
            StatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar.fill") }
            HistoryView()
                .tabItem { Label("History", systemImage: "clock.fill") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(IvoryTheme.accent)
    }
}

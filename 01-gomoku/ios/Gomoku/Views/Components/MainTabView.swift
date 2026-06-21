import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            GameView()
                .tabItem { Label("Play", systemImage: "circle.grid.3x3.fill") }
            HistoryView()
                .tabItem { Label("History", systemImage: "clock.fill") }
            StatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar.fill") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}

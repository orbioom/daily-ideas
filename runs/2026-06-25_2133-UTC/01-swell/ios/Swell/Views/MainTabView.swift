import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            LogView()
                .tabItem {
                    Label("Log", systemImage: "water.waves")
                }
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "list.bullet.clipboard")
                }
            QuiverView()
                .tabItem {
                    Label("Quiver", systemImage: "surfboard.fill")
                }
            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.line.uptrend.xyaxis")
                }
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .tint(SwellTheme.teal)
    }
}

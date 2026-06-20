import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Play", systemImage: "shield.fill") }

            StatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar.fill") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(RampartTheme.gold)
        .toolbarBackground(RampartTheme.surface.opacity(0.95), for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}

import SwiftUI

/// The five-tab main interface. Settings is reachable from the Cook tab toolbar.
struct MainTabView: View {
    var body: some View {
        TabView {
            CookScreen()
                .tabItem { Label("Cook", systemImage: "flame.fill") }

            CooksScreen()
                .tabItem { Label("Cooks", systemImage: "list.bullet.rectangle") }

            GuideScreen()
                .tabItem { Label("Guide", systemImage: "thermometer.medium") }

            RubsScreen()
                .tabItem { Label("Rubs", systemImage: "fork.knife") }

            StatsScreen()
                .tabItem { Label("Stats", systemImage: "chart.bar.xaxis") }
        }
    }
}

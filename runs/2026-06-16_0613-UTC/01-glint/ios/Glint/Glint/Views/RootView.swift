import SwiftUI

struct RootView: View {
    @State private var tab: Tab = .levels

    enum Tab: Hashable {
        case levels, zen, daily, stats, settings
    }

    var body: some View {
        TabView(selection: $tab) {
            LevelsView()
                .tabItem { Label("Levels", systemImage: "square.grid.3x3.fill") }
                .tag(Tab.levels)

            ZenView()
                .tabItem { Label("Zen", systemImage: "infinity") }
                .tag(Tab.zen)

            DailyView()
                .tabItem { Label("Daily", systemImage: "calendar") }
                .tag(Tab.daily)

            StatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar.fill") }
                .tag(Tab.stats)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(Tab.settings)
        }
    }
}

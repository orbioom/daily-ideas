import SwiftUI

/// Root tab navigation: four substantive feature tabs plus Settings.
struct RootView: View {
    @State private var selection: Tab = .packs

    enum Tab: Hashable {
        case packs, daily, stats, settings
    }

    var body: some View {
        TabView(selection: $selection) {
            PacksView()
                .tabItem { Label("Packs", systemImage: "square.grid.2x2.fill") }
                .tag(Tab.packs)

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
        .tint(Theme.accent)
    }
}

import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @State private var selectedTab: Tab = .home
    @State private var didSeed = false

    enum Tab: Hashable { case home, daily, stats, settings }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem { Label("Play", systemImage: "mountain.2.fill") }
                .tag(Tab.home)

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
        .task {
            guard !didSeed else { return }
            didSeed = true
            SeedData.seedIfNeeded(context)
        }
    }
}

import SwiftUI
import SwiftData

/// Root tab navigation. Home, Stats, Learn, History, Settings.
struct RootView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Play", systemImage: "square.grid.3x3.fill") }

            StatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar.fill") }

            LearnView()
                .tabItem { Label("Learn", systemImage: "book.fill") }

            HistoryView()
                .tabItem { Label("History", systemImage: "clock.fill") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(Theme.accent)
    }
}

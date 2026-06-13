import SwiftUI

struct RootView: View {
    @State private var pro = ProStore()

    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "bolt.fill") }
            CategoriesView()
                .tabItem { Label("Categories", systemImage: "square.grid.2x2.fill") }
            StatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar.fill") }
            HistoryView()
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .environment(pro)
        .tint(Theme.accent)
    }
}

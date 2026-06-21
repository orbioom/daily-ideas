import SwiftUI

struct SeekContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                CategoriesView()
            }
            .tabItem {
                Label("Play", systemImage: "text.magnifyingglass")
            }
            .tag(0)

            NavigationStack {
                StatsView()
            }
            .tabItem {
                Label("Stats", systemImage: "chart.bar.fill")
            }
            .tag(1)

            NavigationStack {
                SeekSettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
            .tag(2)
        }
        .tint(SeekTheme.accent)
    }
}

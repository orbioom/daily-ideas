import SwiftUI

/// Root tab interface: Home (SOS), Toolbox, Log, Insights. Settings is reached
/// from a toolbar entry on Home.
struct MainTabView: View {
    @State private var selection: Tab = .home

    enum Tab: Hashable {
        case home, toolbox, log, insights
    }

    var body: some View {
        TabView(selection: $selection) {
            HomeView()
                .tabItem { Label("Home", systemImage: "heart.text.square") }
                .tag(Tab.home)

            ToolboxView()
                .tabItem { Label("Toolbox", systemImage: "bag") }
                .tag(Tab.toolbox)

            LogView()
                .tabItem { Label("Log", systemImage: "book.closed") }
                .tag(Tab.log)

            InsightsView()
                .tabItem { Label("Insights", systemImage: "chart.bar") }
                .tag(Tab.insights)
        }
        .tint(HavenTheme.accent)
    }
}

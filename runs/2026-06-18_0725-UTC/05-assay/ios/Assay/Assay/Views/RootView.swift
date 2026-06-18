import SwiftUI

/// Tab container for the five feature areas.
struct RootView: View {
    @State private var selection: Tab = .dashboard

    enum Tab: Hashable {
        case dashboard, markers, log, history, insights
    }

    var body: some View {
        TabView(selection: $selection) {
            DashboardView()
                .tabItem { Label("Dashboard", systemImage: "square.grid.2x2.fill") }
                .tag(Tab.dashboard)

            MarkersView()
                .tabItem { Label("Markers", systemImage: "list.bullet.rectangle.fill") }
                .tag(Tab.markers)

            LogView()
                .tabItem { Label("Log", systemImage: "plus.circle.fill") }
                .tag(Tab.log)

            HistoryView()
                .tabItem { Label("Panels", systemImage: "calendar") }
                .tag(Tab.history)

            InsightsView()
                .tabItem { Label("Insights", systemImage: "chart.xyaxis.line") }
                .tag(Tab.insights)
        }
        .tint(Theme.accent)
    }
}

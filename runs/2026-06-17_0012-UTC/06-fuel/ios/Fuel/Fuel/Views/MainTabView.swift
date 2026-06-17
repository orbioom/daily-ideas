import SwiftUI

/// The root tabbed experience: Today, Plan, Check-ins, Insights, Settings.
struct MainTabView: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Today", systemImage: "flame.fill") }

            PlanView()
                .tabItem { Label("Plan", systemImage: "slider.horizontal.3") }

            CheckInsView()
                .tabItem { Label("Check-ins", systemImage: "scalemass.fill") }

            InsightsView()
                .tabItem { Label("Insights", systemImage: "chart.xyaxis.line") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(FuelTheme.orange)
    }
}

import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var settings: AppSettings
    @State private var selectedTab = 0
    @State private var didSeed = false

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(selectedTab: $selectedTab)
                .tabItem { Label("Dashboard", systemImage: "square.grid.2x2.fill") }
                .tag(0)

            MeasurementsView()
                .tabItem { Label("Measurements", systemImage: "ruler.fill") }
                .tag(1)

            LogSessionView()
                .tabItem { Label("Log", systemImage: "plus.circle.fill") }
                .tag(2)

            InsightsView()
                .tabItem { Label("Insights", systemImage: "chart.xyaxis.line") }
                .tag(3)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(4)
        }
        .background(Theme.bg.ignoresSafeArea())
        .task {
            // Seed once on first appearance.
            if !didSeed {
                SeedData.seedIfNeeded(modelContext)
                didSeed = true
            }
        }
    }
}

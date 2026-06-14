import SwiftUI
import SwiftData

/// Root tab bar. Seeds sample data on first appearance behind the didSeed flag.
struct RootView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("didSeed") private var didSeed = false

    var body: some View {
        TabView {
            TodayScreen()
                .tabItem { Label("Today", systemImage: "drop.fill") }

            LogbookScreen()
                .tabItem { Label("Logbook", systemImage: "square.grid.3x3") }

            HistoryScreen()
                .tabItem { Label("History", systemImage: "list.bullet") }

            InsightsScreen()
                .tabItem { Label("Insights", systemImage: "chart.xyaxis.line") }

            SettingsScreen()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .task {
            var seeded = didSeed
            SeedData.seedIfNeeded(context: context, didSeed: &seeded)
            didSeed = seeded
        }
    }
}

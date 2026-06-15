import SwiftUI
import SwiftData

/// Root tab bar. Seeds sample holdings on first appearance so charts are non-empty.
struct RootView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("didSeed") private var didSeed = false

    var body: some View {
        TabView {
            PortfolioScreen()
                .tabItem { Label("Portfolio", systemImage: "chart.bar.doc.horizontal") }

            CalendarScreen()
                .tabItem { Label("Calendar", systemImage: "calendar") }

            InsightsScreen()
                .tabItem { Label("Insights", systemImage: "chart.pie") }

            DRIPScreen()
                .tabItem { Label("DRIP", systemImage: "arrow.triangle.2.circlepath") }

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

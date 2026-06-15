import SwiftUI
import SwiftData

/// Root tab container. Seeds example data on first appearance.
struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var didSeed = false

    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Dashboard", systemImage: "square.grid.2x2.fill") }

            SessionsView()
                .tabItem { Label("Sessions", systemImage: "list.bullet.rectangle.fill") }

            AnalyticsView()
                .tabItem { Label("Analytics", systemImage: "chart.bar.fill") }

            BankrollView()
                .tabItem { Label("Bankroll", systemImage: "banknote.fill") }
        }
        .task {
            guard !didSeed else { return }
            didSeed = true
            SeedData.seedIfNeeded(context: modelContext)
        }
    }
}

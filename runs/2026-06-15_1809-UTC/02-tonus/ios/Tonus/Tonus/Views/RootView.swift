import SwiftUI
import SwiftData

/// Root tab container. Seeds example data on first appearance.
struct RootView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "sun.max.fill") }

            ProgramsView()
                .tabItem { Label("Programs", systemImage: "list.bullet.rectangle.portrait.fill") }

            InsightsView()
                .tabItem { Label("Insights", systemImage: "chart.bar.fill") }
        }
        .task {
            SeedData.seedIfNeeded(context: modelContext)
        }
    }
}

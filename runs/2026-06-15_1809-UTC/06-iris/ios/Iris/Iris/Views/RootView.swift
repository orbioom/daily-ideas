import SwiftUI
import SwiftData

/// Root tab container. Seeds example history on first appearance.
struct RootView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "sun.max.fill") }

            ExercisesView()
                .tabItem { Label("Exercises", systemImage: "figure.mind.and.body") }

            InsightsView()
                .tabItem { Label("Insights", systemImage: "chart.bar.fill") }

            ToolsView()
                .tabItem { Label("Tools", systemImage: "slider.horizontal.3") }
        }
        .task {
            SeedData.seedIfNeeded(context: modelContext)
        }
    }
}

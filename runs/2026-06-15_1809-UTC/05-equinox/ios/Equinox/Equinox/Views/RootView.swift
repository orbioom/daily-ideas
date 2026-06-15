import SwiftUI
import SwiftData

/// Root tab container. Seeds example data on first appearance.
struct RootView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "sun.horizon.fill") }

            CalendarView()
                .tabItem { Label("Calendar", systemImage: "calendar") }

            InsightsView()
                .tabItem { Label("Insights", systemImage: "chart.xyaxis.line") }

            LearnView()
                .tabItem { Label("Learn", systemImage: "book.fill") }
        }
        .task {
            SeedData.seedIfNeeded(context: modelContext)
        }
    }
}

import SwiftUI
import SwiftData

/// Root tab container. Seeds example history on first appearance.
struct RootView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        TabView {
            PlayView()
                .tabItem { Label("Play", systemImage: "square.grid.2x2.fill") }

            StatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar.xaxis") }

            AchievementsView()
                .tabItem { Label("Awards", systemImage: "trophy.fill") }

            GuideView()
                .tabItem { Label("Guide", systemImage: "book.fill") }
        }
        .task {
            SeedData.seedIfNeeded(context: modelContext)
        }
    }
}

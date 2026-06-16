import SwiftUI
import SwiftData

/// Root tab container. Seeds example history on first appearance.
struct RootView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        TabView {
            LibraryView()
                .tabItem { Label("Puzzles", systemImage: "square.grid.3x3.fill") }

            DailyView()
                .tabItem { Label("Daily", systemImage: "calendar") }

            StatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar.xaxis") }

            HowToPlayView()
                .tabItem { Label("How to Play", systemImage: "book.fill") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .task {
            SeedData.seedIfNeeded(context: modelContext)
        }
    }
}

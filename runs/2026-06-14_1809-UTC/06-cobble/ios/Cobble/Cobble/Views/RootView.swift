import SwiftUI
import SwiftData

/// Root tab bar. Seeds sample stats on first appearance.
struct RootView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("didSeed") private var didSeed = false

    var body: some View {
        TabView {
            PlayScreen()
                .tabItem { Label("Play", systemImage: "square.grid.3x3.fill") }

            DailyScreen()
                .tabItem { Label("Daily", systemImage: "calendar") }

            LearnScreen()
                .tabItem { Label("How to Play", systemImage: "book") }

            StatsScreen()
                .tabItem { Label("Stats", systemImage: "chart.bar.xaxis") }

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

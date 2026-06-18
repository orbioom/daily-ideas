import SwiftUI
import SwiftData

/// Tab shell. Seeds sample history once on first appearance.
struct RootView: View {
    @Environment(\.modelContext) private var context
    @State private var didSeed = false

    var body: some View {
        TabView {
            DailyView()
                .tabItem { Label("Daily", systemImage: "sun.max.fill") }

            PracticeView()
                .tabItem { Label("Practice", systemImage: "dice.fill") }

            StatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar.fill") }

            MoreView()
                .tabItem { Label("More", systemImage: "ellipsis.circle.fill") }
        }
        .task {
            if !didSeed {
                didSeed = true
                SeedData.seedIfNeeded(context: context)
            }
        }
    }
}

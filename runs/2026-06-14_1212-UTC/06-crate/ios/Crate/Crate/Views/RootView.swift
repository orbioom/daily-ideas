import SwiftUI
import SwiftData

/// Root tab bar. Seeds the sample collection on first appearance.
struct RootView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("didSeed") private var didSeed = false

    var body: some View {
        TabView {
            CollectionScreen()
                .tabItem { Label("Collection", systemImage: "square.grid.2x2.fill") }

            NowSpinningScreen()
                .tabItem { Label("Now Spinning", systemImage: "opticaldisc") }

            WantlistScreen()
                .tabItem { Label("Wantlist", systemImage: "bookmark") }

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

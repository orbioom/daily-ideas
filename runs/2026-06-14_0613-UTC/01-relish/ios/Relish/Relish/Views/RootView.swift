import SwiftUI
import SwiftData

/// Root tab bar. Seeds sample data on first appearance.
struct RootView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("didSeed") private var didSeed = false

    var body: some View {
        TabView {
            ListScreen()
                .tabItem { Label("Your List", systemImage: "list.number") }

            WishlistScreen()
                .tabItem { Label("Want to Try", systemImage: "bookmark") }

            StatsScreen()
                .tabItem { Label("Taste Stats", systemImage: "chart.bar.xaxis") }

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

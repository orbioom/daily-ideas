import SwiftUI
import SwiftData

/// Root tab bar. Seeds a believable solving history on first appearance and keeps
/// the global board palette in sync with the user's chosen theme.
struct RootView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("didSeed") private var didSeed = false

    var body: some View {
        TabView {
            TodayScreen()
                .tabItem { Label("Today", systemImage: "newspaper") }

            ArchiveScreen()
                .tabItem { Label("Archive", systemImage: "square.grid.2x2") }

            StatsScreen()
                .tabItem { Label("Stats", systemImage: "chart.xyaxis.line") }

            SettingsScreen()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .task {
            settings.syncPalette()
            var seeded = didSeed
            SeedData.seedIfNeeded(context: context, didSeed: &seeded)
            didSeed = seeded
        }
    }
}

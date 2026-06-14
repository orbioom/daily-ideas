import SwiftUI
import SwiftData

/// Root tab bar. Seeds genres on first appearance.
struct RootView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("didSeedGenres") private var didSeedGenres = false

    var body: some View {
        TabView {
            LibraryScreen()
                .tabItem { Label("Library", systemImage: "books.vertical.fill") }

            UpNextScreen()
                .tabItem { Label("Up Next", systemImage: "play.circle.fill") }

            BrowseScreen()
                .tabItem { Label("Browse", systemImage: "sparkles") }

            StatsScreen()
                .tabItem { Label("Stats", systemImage: "chart.pie.fill") }

            SettingsScreen()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .task {
            // Always make sure the standard genres exist (cheap & idempotent).
            SeedData.seedGenresIfNeeded(context: context)
            didSeedGenres = true
        }
    }
}

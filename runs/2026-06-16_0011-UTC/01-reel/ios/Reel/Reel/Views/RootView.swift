import SwiftUI
import SwiftData

/// Root tab container. Seeds the sample library once on first appearance.
struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("didSeed") private var didSeed = false

    var body: some View {
        TabView {
            DiaryScreen()
                .tabItem { Label("Diary", systemImage: "book.closed.fill") }

            LibraryScreen()
                .tabItem { Label("Library", systemImage: "square.grid.2x2.fill") }

            WatchlistScreen()
                .tabItem { Label("Watchlist", systemImage: "bookmark.fill") }

            StatsScreen()
                .tabItem { Label("Stats", systemImage: "chart.bar.xaxis") }

            SettingsScreen()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .task {
            var seeded = didSeed
            SeedData.seedIfNeeded(context: modelContext, didSeed: &seeded)
            didSeed = seeded
        }
    }
}

#Preview {
    RootView()
        .environmentObject(AppSettings())
        .modelContainer(PreviewContainer.shared)
}

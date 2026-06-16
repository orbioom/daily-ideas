import SwiftUI
import SwiftData

/// Root tab container. Seeds example data on first appearance.
struct RootView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        TabView {
            DecksScreen()
                .tabItem { Label("Decks", systemImage: "rectangle.stack.fill") }

            StudyHomeScreen()
                .tabItem { Label("Study", systemImage: "play.rectangle.fill") }

            StatsScreen()
                .tabItem { Label("Stats", systemImage: "chart.bar.xaxis") }

            BrowseScreen()
                .tabItem { Label("Browse", systemImage: "magnifyingglass") }

            SettingsScreen()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .task {
            SeedData.seedIfNeeded(context: modelContext)
        }
    }
}

#Preview {
    RootView()
        .environmentObject(AppSettings())
        .modelContainer(PreviewContainer.shared)
}

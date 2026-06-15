import SwiftUI
import SwiftData

/// Root tab container. Seeds example data on first appearance.
struct RootView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "circle.hexagongrid.fill") }

            ProfilesView()
                .tabItem { Label("Profiles", systemImage: "person.2.fill") }

            ExploreView()
                .tabItem { Label("Explore", systemImage: "sparkles") }
        }
        .task {
            SeedData.seedIfNeeded(context: modelContext)
        }
    }
}

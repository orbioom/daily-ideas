import SwiftUI
import SwiftData

/// Root tab bar. Ensures the note library exists on first appearance.
struct RootView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("didSeed") private var didSeed = false

    var body: some View {
        TabView {
            CollectionScreen()
                .tabItem { Label("Collection", systemImage: "square.grid.2x2") }

            TonightScreen()
                .tabItem { Label("Tonight", systemImage: "moon.stars") }

            WishlistScreen()
                .tabItem { Label("Wishlist", systemImage: "heart") }

            StatsScreen()
                .tabItem { Label("Stats", systemImage: "chart.pie") }

            SettingsScreen()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .task {
            // Guarantee the note library is present (cheap, idempotent) without
            // auto-seeding the full sample collection — that's a Settings action.
            NoteLibrary.ensureSeeded(context: context)
        }
    }
}

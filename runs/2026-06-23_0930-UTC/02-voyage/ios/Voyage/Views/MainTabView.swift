import SwiftUI

/// Root tab interface: Decks, Review, Browse, Stats, Settings.
struct MainTabView: View {
    var body: some View {
        TabView {
            DecksView()
                .tabItem { Label("Decks", systemImage: "rectangle.stack.fill") }

            ReviewHomeView()
                .tabItem { Label("Review", systemImage: "brain.head.profile") }

            BrowseView()
                .tabItem { Label("Browse", systemImage: "magnifyingglass") }

            StatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar.fill") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}

#Preview {
    if let container = PersistenceController.previewContainer() {
        MainTabView().modelContainer(container)
    }
}

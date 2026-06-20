import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            CollectionView()
                .tabItem {
                    Label("Collection", systemImage: "rectangle.on.rectangle.angled")
                }
                .tag(0)

            DeckListView()
                .tabItem {
                    Label("Decks", systemImage: "rectangle.stack")
                }
                .tag(1)

            WantListView()
                .tabItem {
                    Label("Wants", systemImage: "heart")
                }
                .tag(2)

            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar")
                }
                .tag(3)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(4)
        }
        .accentColor(SleeveTheme.accent)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    MainTabView()
}

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var srsEngine = SRSEngine()

    var body: some View {
        TabView(selection: $selectedTab) {
            DeckView(srsEngine: srsEngine)
                .tabItem {
                    Label("Study", systemImage: "book.fill")
                }
                .tag(0)

            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }
                .tag(1)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(2)
        }
        .tint(ShuTheme.gold)
        .background(ShuTheme.darkNavy)
        .toolbarBackground(ShuTheme.darkNavy, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarColorScheme(.dark, for: .tabBar)
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [CardReview.self, StudySession.self], inMemory: true)
}

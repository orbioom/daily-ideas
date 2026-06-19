import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Play", systemImage: "play.circle.fill")
                }
                .tag(0)

            BrowseView()
                .tabItem {
                    Label("Browse", systemImage: "list.bullet")
                }
                .tag(1)

            CustomQuestionsView()
                .tabItem {
                    Label("Custom", systemImage: "plus.square.fill")
                }
                .tag(2)
        }
        .tint(VolleyTheme.accent)
    }
}

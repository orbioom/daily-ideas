import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            CurriculumView()
                .tabItem {
                    Label("Learn", systemImage: "book.fill")
                }
                .tag(1)

            FreePianoView()
                .tabItem {
                    Label("Piano", systemImage: "pianokeys")
                }
                .tag(2)

            ProgressView()
                .tabItem {
                    Label("Progress", systemImage: "chart.bar.fill")
                }
                .tag(3)
        }
        .tint(KeysTheme.accent)
    }
}

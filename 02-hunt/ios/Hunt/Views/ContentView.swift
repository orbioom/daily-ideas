import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HuntGameView(isDaily: false)
                .tabItem {
                    Label("Game", systemImage: "gamecontroller.fill")
                }
                .tag(0)

            HuntDailyView()
                .tabItem {
                    Label("Daily", systemImage: "calendar")
                }
                .tag(1)

            HuntStatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }
                .tag(2)

            HuntSettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .tint(HuntTheme.accent)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: HuntResult.self, inMemory: true)
}

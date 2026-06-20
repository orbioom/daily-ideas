import SwiftUI

struct ContentView: View {
    @AppStorage("pace_selected_tab") private var selectedTab = 0
    @Environment(RunEngine.self) private var runEngine

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(0)
            PreRunView()
                .tabItem { Label("Run", systemImage: "figure.run") }
                .tag(1)
            RunHistoryView()
                .tabItem { Label("History", systemImage: "clock.fill") }
                .tag(2)
            PaceStatsView()
                .tabItem { Label("Stats", systemImage: "chart.line.uptrend.xyaxis") }
                .tag(3)
            PaceSettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(4)
        }
        .accentColor(PaceTheme.accent)
    }
}

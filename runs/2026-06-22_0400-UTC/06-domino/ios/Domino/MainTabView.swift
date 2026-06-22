import SwiftUI

struct MainTabView: View {
    let engine: DominoEngine
    let settings: DominoSettings
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            GameView(engine: engine, settings: settings)
                .tabItem { Label("Play", systemImage: "rectangle.fill.on.rectangle.fill") }
                .tag(0)
            HistoryView()
                .tabItem { Label("History", systemImage: "clock.fill") }
                .tag(1)
            RulesView()
                .tabItem { Label("Rules", systemImage: "book.fill") }
                .tag(2)
            StatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar.fill") }
                .tag(3)
            SettingsView(settings: settings, engine: engine)
                .tabItem { Label("Settings", systemImage: "gear") }
                .tag(4)
        }
        .tint(DominoTheme.ivory)
        .preferredColorScheme(.dark)
    }
}

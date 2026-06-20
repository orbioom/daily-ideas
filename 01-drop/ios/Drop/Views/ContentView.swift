import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("drop_selected_tab") private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DropGameView()
                .tabItem { Label("Game", systemImage: "circle.grid.3x3.fill") }
                .tag(0)

            DropStatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar.fill") }
                .tag(1)

            DropSettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(2)
        }
        .accentColor(DropTheme.accent)
        .tint(DropTheme.accent)
    }
}

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            PuzzleSelectView()
                .tabItem {
                    Label("Play", systemImage: "puzzlepiece.fill")
                }

            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .tint(PieceTheme.amber)
        .preferredColorScheme(.dark)
    }
}

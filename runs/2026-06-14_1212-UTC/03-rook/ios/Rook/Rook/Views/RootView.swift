import SwiftUI
import SwiftData

/// Root tab bar with the four feature screens plus Settings.
struct RootView: View {
    var body: some View {
        TabView {
            PlayScreen()
                .tabItem { Label("Play", systemImage: "checkerboard.rectangle") }

            PuzzlesScreen()
                .tabItem { Label("Puzzles", systemImage: "puzzlepiece.extension") }

            StatsScreen()
                .tabItem { Label("Stats", systemImage: "chart.bar.xaxis") }

            LearnScreen()
                .tabItem { Label("Learn", systemImage: "book") }

            SettingsScreen()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}

import SwiftUI

/// The primary tabbed experience: Today, Practice, Stats, Archive, How to Play, Settings.
struct MainTabView: View {
    @State private var selection: Tab = .play

    enum Tab: Hashable { case play, practice, stats, archive, howTo, settings }

    var body: some View {
        TabView(selection: $selection) {
            PlayView()
                .tabItem { Label("Today", systemImage: "square.grid.3x3.fill") }
                .tag(Tab.play)

            PracticeView()
                .tabItem { Label("Practice", systemImage: "infinity") }
                .tag(Tab.practice)

            StatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar.fill") }
                .tag(Tab.stats)

            ArchiveView()
                .tabItem { Label("Archive", systemImage: "calendar") }
                .tag(Tab.archive)

            HowToPlayView()
                .tabItem { Label("How to Play", systemImage: "questionmark.circle") }
                .tag(Tab.howTo)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(Tab.settings)
        }
        .tint(LexTheme.green)
    }
}

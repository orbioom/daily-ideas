import SwiftUI
import SwiftData

/// The primary tabbed experience: Play, New Game, Stats, How to Play, Settings.
struct MainTabView: View {
    @State private var selection: Tab = .play

    enum Tab: Hashable { case play, newGame, stats, howTo, settings }

    var body: some View {
        TabView(selection: $selection) {
            PlayView()
                .tabItem { Label("Play", systemImage: "suit.spade.fill") }
                .tag(Tab.play)

            NewGameTab(selection: $selection)
                .tabItem { Label("New", systemImage: "plus.rectangle.on.rectangle") }
                .tag(Tab.newGame)

            StatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar.fill") }
                .tag(Tab.stats)

            HowToPlayView()
                .tabItem { Label("How to Play", systemImage: "questionmark.circle") }
                .tag(Tab.howTo)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(Tab.settings)
        }
        .tint(SpindleTheme.emerald)
    }
}

/// The "New Game" tab. Because starting a game belongs to the Play screen's live
/// view-model, this tab presents the picker and routes the player to Play with a
/// pending request stored in UserDefaults that PlayView reads on appear.
private struct NewGameTab: View {
    @Binding var selection: MainTabView.Tab

    var body: some View {
        NewGameView { mode, kind in
            // Persist the request, then jump to Play which consumes it.
            PendingGameRequest.set(mode: mode, kind: kind)
            selection = .play
        }
    }
}

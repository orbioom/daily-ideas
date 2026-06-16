import SwiftUI

/// The main tab interface. Four substantive feature tabs plus a settings entry
/// surfaced from within Play/Daily/Stats toolbars.
struct RootView: View {
    @State private var selection: Tab = .play

    enum Tab: Hashable {
        case play, daily, stats, howTo
    }

    var body: some View {
        TabView(selection: $selection) {
            PlayTabView()
                .tabItem { Label("Play", systemImage: "square.grid.3x3.fill") }
                .tag(Tab.play)

            DailyView()
                .tabItem { Label("Daily", systemImage: "calendar") }
                .tag(Tab.daily)

            StatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar.fill") }
                .tag(Tab.stats)

            HowToPlayView()
                .tabItem { Label("How to Play", systemImage: "questionmark.circle.fill") }
                .tag(Tab.howTo)
        }
    }
}

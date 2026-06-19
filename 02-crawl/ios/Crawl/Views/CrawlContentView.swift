import SwiftUI

struct CrawlContentView: View {
    @AppStorage("crawlMode") private var savedMode = GameMode.classic.rawValue

    private var currentMode: GameMode {
        GameMode(rawValue: savedMode) ?? .classic
    }

    var body: some View {
        TabView {
            GameView(mode: currentMode)
                .tabItem { Label("Play", systemImage: "gamecontroller.fill") }

            HighScoresView()
                .tabItem { Label("Scores", systemImage: "trophy.fill") }

            CrawlSettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(.green)
        .preferredColorScheme(.dark)
    }
}

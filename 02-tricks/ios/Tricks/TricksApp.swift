import SwiftUI
import SwiftData

@main
struct TricksApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .modelContainer(for: [SpadesGameRecord.self, TricksSettings.self])
        }
    }
}

struct RootView: View {
    @Query private var settingsArr: [TricksSettings]
    @Environment(\.modelContext) private var ctx

    private var settings: TricksSettings {
        if let s = settingsArr.first { return s }
        let s = TricksSettings(); ctx.insert(s); return s
    }

    var body: some View {
        if settings.hasCompletedOnboarding {
            MainTabView()
        } else {
            OnboardingView()
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            GameView()
                .tabItem { Label("Play", systemImage: "suit.spade.fill") }
            ScoreboardView()
                .tabItem { Label("Scoreboard", systemImage: "list.number") }
            HistoryView()
                .tabItem { Label("History", systemImage: "clock.fill") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(TricksTheme.accent)
    }
}

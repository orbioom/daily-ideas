import SwiftUI
import SwiftData

/// The root tabbed experience: Today, Plan, History, Settings. Owns the shared
/// PlayerEngine so a guided session can be launched from any tab and survives
/// backgrounding / relaunch; presents the player as a full-screen cover.
struct MainTabView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.scenePhase) private var scenePhase
    @Environment(AppSettings.self) private var settings

    @State private var player = PlayerEngine()
    @State private var showPlayer = false

    var body: some View {
        TabView {
            HomeView(player: player, showPlayer: $showPlayer)
                .tabItem { Label("Today", systemImage: "bolt.heart.fill") }

            PlanListView(player: player, showPlayer: $showPlayer)
                .tabItem { Label("Plan", systemImage: "calendar") }

            HistoryView()
                .tabItem { Label("History", systemImage: "chart.bar.fill") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(Theme.coral)
        .fullScreenCover(isPresented: $showPlayer) {
            PlayerView(player: player, isPresented: $showPlayer)
        }
        .task {
            // Resume an in-progress run after relaunch.
            syncCuePrefs()
            if player.restoreIfNeeded() {
                showPlayer = true
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                player.handleScenePhaseActive()
            }
        }
    }

    private func syncCuePrefs() {
        player.voiceCuesEnabled = settings.voiceCuesEnabled
        player.countdownBeepsEnabled = settings.countdownBeeps
        player.hapticsEnabled = settings.hapticCues
    }
}

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab: Int = 0
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("boardColorScheme") private var boardColorSchemeRaw = "Classic"
    @AppStorage("aiDifficulty") private var aiDifficulty = 2
    @AppStorage("gameMode") private var gameModeRaw = "ai"
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true

    @State private var showOnboarding = false

    var body: some View {
        ZStack {
            GammonTheme.background.ignoresSafeArea()

            TabView(selection: $selectedTab) {
                GammonGameView(
                    boardScheme: BoardColorScheme(rawValue: boardColorSchemeRaw) ?? .classic,
                    aiDifficulty: aiDifficulty,
                    gameMode: gameModeRaw == "ai" ? .vsAI(difficulty: aiDifficulty) : .twoPlayer,
                    hapticsEnabled: hapticsEnabled
                )
                .tabItem {
                    Label("Play", systemImage: "gamecontroller.fill")
                }
                .tag(0)

                GammonRulesView()
                    .tabItem {
                        Label("Rules", systemImage: "book.fill")
                    }
                    .tag(1)

                GammonStatsView()
                    .tabItem {
                        Label("Stats", systemImage: "chart.bar.fill")
                    }
                    .tag(2)

                GammonSettingsView(
                    boardColorSchemeRaw: $boardColorSchemeRaw,
                    aiDifficulty: $aiDifficulty,
                    gameModeRaw: $gameModeRaw,
                    hapticsEnabled: $hapticsEnabled
                )
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(3)
            }
            .tint(GammonTheme.accent)
        }
        .onAppear {
            configureTabBarAppearance()
            if !hasSeenOnboarding {
                showOnboarding = true
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            GammonOnboardingView {
                hasSeenOnboarding = true
                showOnboarding = false
            }
        }
    }

    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(GammonTheme.surface)
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(GammonTheme.accent)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(GammonTheme.accent)
        ]
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(GammonTheme.textMuted)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(GammonTheme.textMuted)
        ]
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

#Preview {
    ContentView()
        .modelContainer(for: GammonResult.self, inMemory: true)
}

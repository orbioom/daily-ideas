import SwiftUI

struct MainTabView: View {
    var engine: BinauralEngine

    @State private var selectedTab: Tab = .home
    @State private var showPlayer = false
    @State private var playerPreset: HaloPreset?

    enum Tab: String, CaseIterable {
        case home = "Home"
        case sessions = "Sessions"
        case insights = "Insights"
        case learn = "Learn"
        case settings = "Settings"

        var icon: String {
            switch self {
            case .home:     return "house.fill"
            case .sessions: return "clock.fill"
            case .insights: return "chart.bar.fill"
            case .learn:    return "book.fill"
            case .settings: return "gearshape.fill"
            }
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView(engine: engine, onSelectPreset: { preset in
                    playerPreset = preset
                    showPlayer = true
                })
                .tag(Tab.home)

                SessionsView()
                    .tag(Tab.sessions)

                InsightsView()
                    .tag(Tab.insights)

                LearnView()
                    .tag(Tab.learn)

                SettingsView(engine: engine)
                    .tag(Tab.settings)
            }
            .tabViewStyle(.tabBarOnly)
            .toolbarBackground(HaloTheme.background.opacity(0.95), for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
            .tint(HaloTheme.accent)

            // Now Playing bar overlays above tab bar when session is active
            if engine.isPlaying {
                VStack(spacing: 0) {
                    NowPlayingBar(engine: engine, onTap: {
                        if let preset = engine.sessionPreset {
                            playerPreset = preset
                            showPlayer = true
                        }
                    })
                    .padding(.bottom, 49) // tab bar height
                }
            }
        }
        .fullScreenCover(isPresented: $showPlayer) {
            if let preset = playerPreset {
                PlayerView(engine: engine, preset: preset)
            }
        }
        .preferredColorScheme(.dark)
    }
}

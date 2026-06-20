import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var settingsQ: [RivalSettings]

    var body: some View {
        if settingsQ.first?.onboardingComplete == true {
            mainTabs
        } else {
            RivalOnboardingView()
        }
    }

    private var mainTabs: some View {
        TabView {
            PicksListView()
                .tabItem { Label("Picks", systemImage: "target") }

            LeaguesView()
                .tabItem { Label("Leagues", systemImage: "trophy.fill") }

            RivalStatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar.fill") }

            RivalSettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(RivalTheme.accent)
    }
}

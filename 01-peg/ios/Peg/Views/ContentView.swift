import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var onboardingQuery: [PegOnboarding]

    var body: some View {
        if onboardingQuery.first?.completed == true {
            mainTabs
        } else {
            OnboardingView()
        }
    }

    private var mainTabs: some View {
        TabView {
            GameView()
                .tabItem { Label("Play", systemImage: "suit.club.fill") }
            StatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar.fill") }
            NavigationStack {
                SettingsView()
            }
            .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(PegTheme.goldAccent)
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(PegTheme.feltGreenDark)
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

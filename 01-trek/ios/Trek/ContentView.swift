import SwiftUI

struct ContentView: View {
    @AppStorage(TrekSettings.onboardingCompleted) private var onboardingDone = false

    var body: some View {
        if !onboardingDone {
            OnboardingView()
        } else {
            MainTabView()
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            TrailsView()
                .tabItem {
                    Label("Trails", systemImage: "map.fill")
                }

            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .tint(TrekTheme.forestGreen)
    }
}

import SwiftUI
import SwiftData
import UIKit

struct ContentView: View {
    @Query private var onboardingQuery: [PebbleOnboarding]

    var body: some View {
        if onboardingQuery.first?.completed == true {
            TabView {
                GameView()
                    .tabItem { Label("Play", systemImage: "circle.grid.3x3.fill") }
                StatsView()
                    .tabItem { Label("Stats", systemImage: "chart.bar.fill") }
                NavigationStack { SettingsView() }
                    .tabItem { Label("Settings", systemImage: "gearshape.fill") }
            }
            .tint(PebbleTheme.sandGold)
            .onAppear {
                let appearance = UITabBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = UIColor(PebbleTheme.woodBrown)
                UITabBar.appearance().standardAppearance = appearance
                UITabBar.appearance().scrollEdgeAppearance = appearance
            }
        } else {
            OnboardingView()
        }
    }
}

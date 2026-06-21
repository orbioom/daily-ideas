import SwiftUI
import SwiftData
import UIKit

struct ContentView: View {
    @Query private var onboardingList: [DraughtsOnboarding]

    private var hasCompletedOnboarding: Bool {
        onboardingList.first?.hasCompletedOnboarding ?? false
    }

    var body: some View {
        if hasCompletedOnboarding {
            mainTabView
        } else {
            OnboardingView()
        }
    }

    private var mainTabView: some View {
        TabView {
            GameView()
                .tabItem {
                    Label("Game", systemImage: "checkerboard.rectangle")
                }

            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .tint(DraughtsTheme.gold)
        .onAppear {
            // Style the tab bar to match the dark wood aesthetic
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(DraughtsTheme.background)

            let itemAppearance = UITabBarItemAppearance()
            itemAppearance.normal.iconColor = UIColor(DraughtsTheme.text.opacity(0.45))
            itemAppearance.normal.titleTextAttributes = [
                .foregroundColor: UIColor(DraughtsTheme.text.opacity(0.45))
            ]
            itemAppearance.selected.iconColor = UIColor(DraughtsTheme.gold)
            itemAppearance.selected.titleTextAttributes = [
                .foregroundColor: UIColor(DraughtsTheme.gold)
            ]

            appearance.stackedLayoutAppearance = itemAppearance
            appearance.inlineLayoutAppearance = itemAppearance
            appearance.compactInlineLayoutAppearance = itemAppearance

            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [DraughtsStats.self, DraughtsSettings.self, DraughtsOnboarding.self], inMemory: true)
}

import SwiftUI

struct RootView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true

    var body: some View {
        Group {
            if hasOnboarded {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .onAppear { Haptics.enabled = hapticsEnabled }
        .onChange(of: hapticsEnabled) { _, enabled in Haptics.enabled = enabled }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            DecksListView()
                .tabItem { Label("Decks", systemImage: "rectangle.stack") }
            InsightsView()
                .tabItem { Label("Progress", systemImage: "chart.bar.xaxis") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .tint(Brand.text)
    }
}

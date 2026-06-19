import SwiftUI

struct CastContentView: View {
    @AppStorage(CastSettings.onboardingDone) private var onboardingDone = false

    var body: some View {
        if !onboardingDone {
            CastOnboardingView()
        } else {
            CastTabView()
        }
    }
}

struct CastTabView: View {
    var body: some View {
        TabView {
            ShowsView()
                .tabItem { Label("Shows", systemImage: "mic.fill") }

            QueueView()
                .tabItem { Label("Queue", systemImage: "list.bullet") }

            CastStatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar.fill") }

            CastSettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
        }
        .tint(CastTheme.purple)
    }
}

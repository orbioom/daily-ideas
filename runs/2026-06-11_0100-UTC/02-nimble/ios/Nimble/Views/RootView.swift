import SwiftUI

struct RootView: View {
    @AppStorage("nimble.onboardingDone") private var onboardingDone = false

    var body: some View {
        if !onboardingDone {
            OnboardingView()
        } else {
            TabView {
                NavigationStack {
                    HomeView()
                }
                .tabItem {
                    Label("Train", systemImage: "brain.head.profile")
                }

                NavigationStack {
                    StatsView()
                }
                .tabItem {
                    Label("Progress", systemImage: "chart.bar")
                }

                NavigationStack {
                    SettingsView()
                }
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
            }
        }
    }
}

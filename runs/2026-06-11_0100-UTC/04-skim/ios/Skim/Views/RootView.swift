import SwiftUI

struct RootView: View {
    @AppStorage("skim.onboardingDone") private var onboardingDone = false

    var body: some View {
        if !onboardingDone {
            OnboardingView()
        } else {
            TabView {
                NavigationStack {
                    LibraryView()
                }
                .tabItem {
                    Label("Library", systemImage: "books.vertical")
                }

                NavigationStack {
                    StatsView()
                }
                .tabItem {
                    Label("Stats", systemImage: "chart.line.uptrend.xyaxis")
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

import SwiftUI

struct RootView: View {
    @AppStorage("weave.onboardingDone") private var onboardingDone = false
    @State private var tab: Tab = .today

    enum Tab { case today, archive, settings }

    var body: some View {
        if !onboardingDone {
            OnboardingView()
        } else {
            TabView(selection: $tab) {
                NavigationStack {
                    TodayView()
                }
                .tabItem {
                    Label("Today", systemImage: "sun.max")
                }
                .tag(Tab.today)

                NavigationStack {
                    ArchiveView()
                }
                .tabItem {
                    Label("Archive", systemImage: "calendar")
                }
                .tag(Tab.archive)

                NavigationStack {
                    SettingsView()
                }
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(Tab.settings)
            }
        }
    }
}

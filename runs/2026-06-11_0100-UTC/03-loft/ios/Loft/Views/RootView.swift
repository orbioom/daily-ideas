import SwiftUI

struct RootView: View {
    @AppStorage("loft.onboardingDone") private var onboardingDone = false

    var body: some View {
        if !onboardingDone {
            OnboardingView()
        } else {
            TabView {
                NavigationStack {
                    BoardsListView()
                }
                .tabItem {
                    Label("Boards", systemImage: "photo.on.rectangle.angled")
                }

                NavigationStack {
                    GoalsView()
                }
                .tabItem {
                    Label("Goals", systemImage: "target")
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

import SwiftUI

/// Top-level tab container. Four tabs: Home, Atlas, Progress, Settings.
struct RootView: View {
    @State private var selection: Tab = .home

    enum Tab: Hashable {
        case home, atlas, progress, settings
    }

    var body: some View {
        TabView(selection: $selection) {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(Tab.home)

            AtlasView()
                .tabItem { Label("Atlas", systemImage: "globe") }
                .tag(Tab.atlas)

            ProgressDashboardView()
                .tabItem { Label("Progress", systemImage: "chart.bar.fill") }
                .tag(Tab.progress)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(Tab.settings)
        }
    }
}

#Preview {
    RootView()
        .modelContainer(for: [CountryProgress.self, QuizSession.self], inMemory: true)
}

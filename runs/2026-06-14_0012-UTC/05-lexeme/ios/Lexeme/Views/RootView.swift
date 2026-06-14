import SwiftUI

/// App-level tab identity, shared so screens can request navigation to another tab.
enum AppTab: Hashable { case today, study, lexicon, progress, settings }

/// The main shell: four feature tabs plus Settings.
struct RootView: View {
    @State private var selection: AppTab = .today

    var body: some View {
        TabView(selection: $selection) {
            TodayView(goToTab: { selection = $0 })
                .tabItem { Label("Today", systemImage: "sun.max") }
                .tag(AppTab.today)

            StudyHomeView()
                .tabItem { Label("Study", systemImage: "graduationcap") }
                .tag(AppTab.study)

            LexiconView()
                .tabItem { Label("Lexicon", systemImage: "books.vertical") }
                .tag(AppTab.lexicon)

            ProgressDashboardView()
                .tabItem { Label("Progress", systemImage: "chart.line.uptrend.xyaxis") }
                .tag(AppTab.progress)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(AppTab.settings)
        }
        .tint(Theme.accent)
    }
}

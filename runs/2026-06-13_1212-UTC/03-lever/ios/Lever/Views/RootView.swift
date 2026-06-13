import SwiftUI

/// The four feature tabs plus Settings. Each tab owns its own NavigationStack.
struct RootView: View {
    @State private var pro = ProStore()

    var body: some View {
        TabView {
            TrainView()
                .tabItem { Label("Train", systemImage: "bolt.fill") }
            SkillsView()
                .tabItem { Label("Skills", systemImage: "list.bullet.indent") }
            TestView()
                .tabItem { Label("Test", systemImage: "stopwatch.fill") }
            ProgressDashboardView()
                .tabItem { Label("Progress", systemImage: "chart.bar.fill") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .environment(pro)
        .tint(Theme.accent)
    }
}

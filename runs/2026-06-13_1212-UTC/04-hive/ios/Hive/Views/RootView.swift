import SwiftUI

/// The four feature tabs plus Settings. Each tab owns its own NavigationStack.
struct RootView: View {
    @State private var pro = ProStore()

    var body: some View {
        TabView {
            DailyView()
                .tabItem { Label("Daily", systemImage: "hexagon.fill") }
            PracticeView()
                .tabItem { Label("Practice", systemImage: "infinity") }
            ArchiveView()
                .tabItem { Label("Archive", systemImage: "calendar") }
            StatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar.fill") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .environment(pro)
        .tint(Theme.accent)
    }
}

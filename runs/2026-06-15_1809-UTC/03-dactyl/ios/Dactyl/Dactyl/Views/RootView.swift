import SwiftUI
import SwiftData

/// Root tab container. Seeds example data on first appearance.
struct RootView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        TabView {
            LessonsView()
                .tabItem { Label("Lessons", systemImage: "graduationcap.fill") }

            TestView()
                .tabItem { Label("Test", systemImage: "stopwatch.fill") }

            StatsView()
                .tabItem { Label("Stats", systemImage: "chart.line.uptrend.xyaxis") }

            KeysView()
                .tabItem { Label("Keys", systemImage: "keyboard.fill") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .task {
            SeedData.seedIfNeeded(context: modelContext)
        }
    }
}

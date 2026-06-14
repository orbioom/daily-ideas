import SwiftUI
import SwiftData

/// Root tab bar. Seeds sample data on first appearance.
struct RootView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("didSeed") private var didSeed = false

    var body: some View {
        TabView {
            PracticeHomeView()
                .tabItem { Label("Practice", systemImage: "music.note") }

            LearnView()
                .tabItem { Label("Learn", systemImage: "book.fill") }

            ProgressScreen()
                .tabItem { Label("Progress", systemImage: "chart.bar.fill") }

            SettingsScreen()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .task {
            var seeded = didSeed
            SeedData.seedIfNeeded(context: context, didSeed: &seeded)
            didSeed = seeded
        }
    }
}

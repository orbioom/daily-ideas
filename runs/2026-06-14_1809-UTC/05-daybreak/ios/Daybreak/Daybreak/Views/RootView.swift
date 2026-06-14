import SwiftUI
import SwiftData

/// Root tab bar. Seeds sample data on first appearance.
struct RootView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("didSeed") private var didSeed = false

    var body: some View {
        TabView {
            TodayScreen()
                .tabItem { Label("Today", systemImage: "sun.max") }

            LibraryScreen()
                .tabItem { Label("Routines", systemImage: "list.bullet.rectangle") }

            ProgressScreen()
                .tabItem { Label("Progress", systemImage: "chart.bar.xaxis") }

            SettingsScreen()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .task {
            var seeded = didSeed
            SeedData.seedIfNeeded(context: context, didSeed: &seeded)
            didSeed = seeded
        }
    }
}

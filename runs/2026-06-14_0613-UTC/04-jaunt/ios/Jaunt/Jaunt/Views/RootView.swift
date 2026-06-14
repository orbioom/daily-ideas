import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @State private var didSeedThisLaunch = false

    var body: some View {
        TabView {
            TripsView()
                .tabItem { Label("Trips", systemImage: "suitcase.rolling") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .task {
            // Seed sample data once on first launch.
            guard !didSeedThisLaunch else { return }
            didSeedThisLaunch = true
            SeedData.seedIfNeeded(context: context)
        }
    }
}

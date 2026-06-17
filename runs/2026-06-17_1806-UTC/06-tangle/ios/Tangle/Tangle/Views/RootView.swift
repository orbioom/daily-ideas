import SwiftUI
import SwiftData

/// The main tab interface. Seeds first-run data, then offers the four feature
/// areas plus Settings.
struct RootView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        TabView {
            LevelsMapView()
                .tabItem { Label("Play", systemImage: "square.grid.3x3.fill") }

            DailyView()
                .tabItem { Label("Daily", systemImage: "calendar") }

            WordJarView()
                .tabItem { Label("Word Jar", systemImage: "sparkles") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(Theme.accent)
        .onAppear { SeedData.seedIfNeeded(modelContext) }
    }
}

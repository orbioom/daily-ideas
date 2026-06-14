import SwiftUI
import SwiftData

/// Tab shell. Seeds the library on first appearance.
struct RootView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        TabView {
            LibraryView()
                .tabItem { Label("Library", systemImage: "square.grid.2x2.fill") }

            PickNextView()
                .tabItem { Label("Play Next", systemImage: "dice.fill") }

            YearInGamesView()
                .tabItem { Label("Year", systemImage: "trophy.fill") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .task {
            SeedData.seedIfNeeded(modelContext)
        }
    }
}

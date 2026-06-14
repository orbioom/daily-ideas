import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("didSeed") private var didSeed = false
    @Query private var games: [BoardGame]

    var body: some View {
        TabView {
            CollectionView()
                .tabItem { Label("Collection", systemImage: "square.grid.2x2.fill") }

            PlayPickerView()
                .tabItem { Label("Picker", systemImage: "dice.fill") }

            StatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar.xaxis") }

            PlayersView()
                .tabItem { Label("Players", systemImage: "person.2.fill") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(Theme.accent)
        .task {
            // Seed once, only if the store is genuinely empty.
            if !didSeed && games.isEmpty {
                SeedData.seed(into: context)
                didSeed = true
            }
        }
    }
}

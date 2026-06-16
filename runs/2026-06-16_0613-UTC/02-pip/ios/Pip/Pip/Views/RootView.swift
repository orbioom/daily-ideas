import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @State private var didSeed = false

    var body: some View {
        TabView {
            PlayHomeView()
                .tabItem { Label("Play", systemImage: "dice.fill") }

            DailyView()
                .tabItem { Label("Daily", systemImage: "calendar") }

            StatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar.xaxis") }

            HistoryView()
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(Theme.accent)
        .task {
            if !didSeed {
                didSeed = true
                SeedData.seedIfNeeded(context: context)
            }
        }
    }
}

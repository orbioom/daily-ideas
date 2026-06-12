import SwiftUI
import SwiftData

@main
struct CheckpointApp: App {
    @AppStorage("hasOnboarded") private var hasOnboarded = false

    var body: some Scene {
        WindowGroup {
            Group {
                if hasOnboarded {
                    RootView()
                } else {
                    OnboardingView()
                }
            }
            .tint(Theme.accent)
        }
        .modelContainer(for: [Game.self, PlaySession.self])
    }
}

struct RootView: View {
    @Environment(\.modelContext) private var context

    var body: some View {
        TabView {
            LibraryView()
                .tabItem { Label("Library", systemImage: "square.stack.fill") }
            ShuffleView()
                .tabItem { Label("Shuffle", systemImage: "dice.fill") }
            StatsView()
                .tabItem { Label("Stats", systemImage: "chart.pie.fill") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .task { SeedData.installIfNeeded(context: context) }
    }
}

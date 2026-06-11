import SwiftUI
import SwiftData

@main
struct RompApp: App {
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
        .modelContainer(for: [GameResult.self, CustomDeck.self])
    }
}

struct RootView: View {
    var body: some View {
        TabView {
            DecksView()
                .tabItem { Label("Play", systemImage: "party.popper") }
            StatsView()
                .tabItem { Label("Scores", systemImage: "trophy") }
            CustomDecksView()
                .tabItem { Label("My decks", systemImage: "rectangle.stack.badge.plus") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}

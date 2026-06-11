import SwiftUI
import SwiftData

@main
struct DeckApp: App {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some Scene {
        WindowGroup {
            if hasSeenOnboarding {
                DeckRootView()
            } else {
                DeckOnboardingView(isComplete: $hasSeenOnboarding)
            }
        }
        .modelContainer(for: [FlashDeck.self, FlashCard.self, CardReview.self])
    }
}

struct DeckRootView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DecksView()
                .tabItem { Label("Decks", systemImage: "rectangle.stack.fill") }
                .tag(0)

            DeckStatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar.fill") }
                .tag(1)

            DeckSettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
                .tag(2)
        }
        .tint(DeckTheme.accent)
    }
}

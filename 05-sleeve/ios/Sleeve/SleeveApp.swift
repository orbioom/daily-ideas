import SwiftUI
import SwiftData

@main
struct SleeveApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: Card.self, Deck.self, DeckEntry.self, WantCard.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .modelContainer(container)
        }
    }
}

struct RootView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some View {
        if hasSeenOnboarding {
            MainTabView()
        } else {
            OnboardingView()
        }
    }
}

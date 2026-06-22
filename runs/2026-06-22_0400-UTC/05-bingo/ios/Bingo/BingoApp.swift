import SwiftUI
import SwiftData

@main
struct BingoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [BingoGame.self, SavedCard.self, CustomPack.self, BingoSettings.self])
    }
}

struct ContentView: View {
    @Query private var settings: [BingoSettings]

    var body: some View {
        if let s = settings.first, s.hasCompletedOnboarding {
            MainTabView()
        } else {
            OnboardingView()
        }
    }
}

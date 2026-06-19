import SwiftUI
import SwiftData

@main
struct BrickApp: App {
    var body: some Scene {
        WindowGroup {
            BrickRootView()
        }
        .modelContainer(for: BrickHighScore.self)
    }
}

struct BrickRootView: View {
    @AppStorage("brickHasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some View {
        if hasSeenOnboarding {
            BrickContentView()
        } else {
            BrickOnboardingView()
        }
    }
}

import SwiftUI
import SwiftData

@main
struct HoopApp: App {
    var body: some Scene {
        WindowGroup { ContentView() }
            .modelContainer(for: [HoopGame.self, HoopPlayer.self])
    }
}

struct ContentView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    var body: some View {
        if hasSeenOnboarding { MainTabView() } else { OnboardingView() }
    }
}

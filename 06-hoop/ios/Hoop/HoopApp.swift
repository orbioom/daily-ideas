import SwiftUI
import SwiftData

@main
struct HoopApp: App {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([HoopGame.self, HoopPlayer.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            if hasSeenOnboarding {
                MainTabView()
                    .preferredColorScheme(.dark)
            } else {
                OnboardingView(hasSeenOnboarding: $hasSeenOnboarding)
                    .preferredColorScheme(.dark)
            }
        }
        .modelContainer(sharedModelContainer)
    }
}

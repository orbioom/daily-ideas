import SwiftUI
import SwiftData

@main
struct SwatchApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Palette.self, SwatchColor.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some Scene {
        WindowGroup {
            if hasSeenOnboarding {
                MainTabView()
                    .preferredColorScheme(.light)
            } else {
                OnboardingView(hasSeenOnboarding: $hasSeenOnboarding)
                    .preferredColorScheme(.light)
            }
        }
        .modelContainer(sharedModelContainer)
    }
}

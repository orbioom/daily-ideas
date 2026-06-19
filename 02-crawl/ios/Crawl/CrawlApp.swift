import SwiftUI
import SwiftData

@main
struct CrawlApp: App {
    var body: some Scene {
        WindowGroup {
            CrawlRootView()
        }
        .modelContainer(for: HighScore.self)
    }
}

struct CrawlRootView: View {
    @AppStorage("crawlHasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some View {
        if hasSeenOnboarding {
            CrawlContentView()
        } else {
            CrawlOnboardingView()
        }
    }
}

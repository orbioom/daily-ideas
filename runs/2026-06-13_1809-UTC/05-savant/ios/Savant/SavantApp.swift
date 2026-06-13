import SwiftUI
import SwiftData

@main
struct SavantApp: App {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: GameResult.self)
        } catch {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            container = try! ModelContainer(for: GameResult.self, configurations: config)
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if hasOnboarded { RootView() } else { OnboardingView() }
            }
            .tint(Theme.accent)
        }
        .modelContainer(container)
    }
}

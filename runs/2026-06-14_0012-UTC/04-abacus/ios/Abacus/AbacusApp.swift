import SwiftUI
import SwiftData

@main
struct AbacusApp: App {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: LoanScenario.self)
        } catch {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            // The only permitted try! per build conventions: in-memory fallback.
            container = try! ModelContainer(for: LoanScenario.self, configurations: config)
        }
    }

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
        .modelContainer(container)
    }
}

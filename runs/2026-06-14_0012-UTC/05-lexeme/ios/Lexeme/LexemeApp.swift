import SwiftUI
import SwiftData

@main
struct LexemeApp: App {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: WordProgress.self, StudySession.self)
        } catch {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            // The ONLY sanctioned try! per conventions: in-memory fallback.
            container = try! ModelContainer(for: WordProgress.self, StudySession.self, configurations: config)
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

import SwiftUI
import SwiftData

@main
struct FretworkApp: App {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: PracticeSession.self)
        } catch {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            container = try! ModelContainer(for: PracticeSession.self, configurations: config)
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

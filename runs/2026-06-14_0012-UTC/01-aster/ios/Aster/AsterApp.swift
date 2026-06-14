import SwiftUI
import SwiftData

@main
struct AsterApp: App {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: MindMap.self, MapNode.self)
        } catch {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            // Allowed `try!` per conventions: in-memory fallback only.
            container = try! ModelContainer(for: MindMap.self, MapNode.self, configurations: config)
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

import SwiftUI
import SwiftData

@main
struct VersoApp: App {
    @AppStorage("hasOnboarded") private var hasOnboarded = false

    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: Note.self, Folder.self, Tag.self)
        } catch {
            // A failed store is unrecoverable at launch; fall back to in-memory so the
            // app still opens rather than crashing the user out.
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            container = try! ModelContainer(for: Note.self, Folder.self, Tag.self, configurations: config)
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

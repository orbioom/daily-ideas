import SwiftUI
import SwiftData

@main
struct EpigraphApp: App {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: Book.self, Highlight.self, Tag.self)
        } catch {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            container = try! ModelContainer(for: Book.self, Highlight.self, Tag.self, configurations: config)
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

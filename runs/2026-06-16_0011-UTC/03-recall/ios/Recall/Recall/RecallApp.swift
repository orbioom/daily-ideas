import SwiftUI
import SwiftData

@main
struct RecallApp: App {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @AppStorage("appearance") private var appearanceRaw = AppearanceMode.system.rawValue
    @StateObject private var settings = AppSettings()

    let container: ModelContainer

    init() {
        let schema = Schema([Deck.self, Card.self, ReviewLog.self])
        if let onDisk = try? ModelContainer(for: schema) {
            container = onDisk
        } else {
            container = RecallApp.makeInMemoryContainer(
                schema: schema,
                configuration: ModelConfiguration(isStoredInMemoryOnly: true))
        }
    }

    /// Builds an in-memory container. This is the app's single documented fallback:
    /// an empty in-memory store cannot fail to build, so the `fatalError` is unreachable.
    /// Shared with `PreviewContainer` so there is exactly one `fatalError` in the codebase.
    static func makeInMemoryContainer(schema: Schema, configuration: ModelConfiguration) -> ModelContainer {
        if let mem = try? ModelContainer(for: schema, configurations: configuration) {
            return mem
        }
        // Unreachable: an empty in-memory store cannot fail to build.
        fatalError("Unable to initialize ModelContainer.")
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
            .environmentObject(settings)
            .tint(Theme.accent)
            .preferredColorScheme(AppearanceMode(rawValue: appearanceRaw)?.colorScheme)
        }
        .modelContainer(container)
    }
}

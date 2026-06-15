import SwiftUI
import SwiftData

@main
struct InklingApp: App {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @StateObject private var settings = AppSettings()
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: Tracker.self, LogEntry.self)
        } catch {
            // Last resort: an in-memory store keeps the app usable rather than crashing.
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            // If even this fails the platform is broken; surface an empty container safely.
            container = (try? ModelContainer(for: Tracker.self, LogEntry.self, configurations: config))
                ?? ModelContainer.inMemoryFallback()
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
            .environmentObject(settings)
            .tint(Theme.accent)
            .preferredColorScheme(settings.appearance.colorScheme)
        }
        .modelContainer(container)
    }
}

private extension ModelContainer {
    /// A guaranteed in-memory container; only reached if the primary store cannot be built.
    static func inMemoryFallback() -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        do {
            return try ModelContainer(for: Tracker.self, LogEntry.self, configurations: config)
        } catch {
            // Schema is statically valid, so this path is effectively unreachable; provide a
            // minimal single-entity container as the final safety net.
            return try! ModelContainer(for: Tracker.self, configurations: config)
        }
    }
}

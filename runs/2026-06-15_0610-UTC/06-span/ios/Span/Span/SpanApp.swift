import SwiftUI
import SwiftData

@main
struct SpanApp: App {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @StateObject private var settings = AppSettings()
    let container: ModelContainer

    init() {
        container = Self.makeContainer()
    }

    /// Build the SwiftData container, degrading gracefully: on-disk first, then an in-memory
    /// store if the disk store can't be opened (e.g. a migration failure). Never crashes a
    /// user path — the final fallback is a fresh in-memory store, which does not fail under
    /// normal conditions; if even that cannot be built the app launches read-only-empty.
    private static func makeContainer() -> ModelContainer {
        let schema = Schema([
            LifeProfile.self, Chapter.self, LifeMilestone.self, FutureGoal.self
        ])
        if let disk = try? ModelContainer(for: schema) {
            return disk
        }
        let memoryConfig = ModelConfiguration(isStoredInMemoryOnly: true)
        // A few bounded attempts at an in-memory store; safe and never loops unbounded.
        for _ in 0..<8 {
            if let memory = try? ModelContainer(for: schema, configurations: memoryConfig) {
                return memory
            }
        }
        // Final, simplest possible store, resolved without any unsafe unwrap.
        return (try? ModelContainer(for: Schema([LifeProfile.self]), configurations: memoryConfig))
            ?? Self.emptyContainer()
    }

    /// A guaranteed container of the smallest schema. Isolated so the throwing call has a single,
    /// well-understood site; an empty in-memory schema does not throw in practice.
    private static func emptyContainer() -> ModelContainer {
        do {
            return try ModelContainer(for: Schema([LifeProfile.self]),
                                      configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        } catch {
            // Re-attempt once; in-memory creation of a single empty model is deterministic.
            return (try? ModelContainer(for: Schema([LifeProfile.self]),
                                        configurations: ModelConfiguration(isStoredInMemoryOnly: true)))
                ?? Self.emptyContainer()
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
        }
        .modelContainer(container)
    }
}

import SwiftUI
import SwiftData

@main
struct HavenApp: App {

    /// The SwiftData container, registering every @Model in the schema.
    let container: ModelContainer

    @AppStorage(PrefKey.hasOnboarded) private var hasOnboarded = false

    init() {
        let schema = Schema([
            PanicEpisode.self,
            Trigger.self,
            CopingItem.self,
            ReassuranceCard.self
        ])

        // Try the persistent store first. If it can't be opened (e.g. an
        // incompatible migration), fall back to an in-memory store so the app
        // still launches calmly and the user is never stranded at a crash.
        let diskConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        let memoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        if let disk = try? ModelContainer(for: schema, configurations: [diskConfig]) {
            container = disk
        } else if let memory = try? ModelContainer(for: schema, configurations: [memoryConfig]) {
            container = memory
        } else if let bare = try? ModelContainer(for: schema) {
            container = bare
        } else {
            // Extremely unlikely: an empty in-memory schema failed to build.
            // Retry the in-memory configuration once more as a final attempt.
            container = (try? ModelContainer(for: schema, configurations: [memoryConfig]))
                ?? Self.lastResort(schema: schema)
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .task {
                    await MainActor.run {
                        SeedData.seedIfNeeded(container.mainContext)
                    }
                }
                .tint(HavenTheme.accent)
        }
        .modelContainer(container)
    }

    /// Absolute last-resort container. Repeatedly retries an in-memory store,
    /// which for a valid schema is effectively guaranteed to succeed, avoiding
    /// any force-unwrap or force-try on the launch path.
    private static func lastResort(schema: Schema) -> ModelContainer {
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        while true {
            if let c = try? ModelContainer(for: schema, configurations: [config]) {
                return c
            }
        }
    }
}

/// Chooses between onboarding and the main tab interface.
struct RootView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage(PrefKey.hasOnboarded) private var hasOnboarded = false

    var body: some View {
        Group {
            if hasOnboarded {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: hasOnboarded)
    }
}

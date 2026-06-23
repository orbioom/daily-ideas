import SwiftUI
import SwiftData

@main
struct SprigApp: App {

    /// The SwiftData container, registering every @Model in the schema.
    let container: ModelContainer

    init() {
        let schema = Schema([
            Baby.self,
            FeedLog.self,
            SleepLog.self,
            DiaperLog.self,
            GrowthEntry.self
        ])

        // Prefer the on-disk store; fall back to in-memory so a corrupt or
        // migration-incompatible store never strands the user at a crash.
        let diskConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        let memoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        if let disk = try? ModelContainer(for: schema, configurations: [diskConfig]) {
            container = disk
        } else if let memory = try? ModelContainer(for: schema, configurations: [memoryConfig]) {
            container = memory
        } else {
            container = Self.lastResort(schema: schema)
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .task {
                    SeedData.seedIfNeeded(container.mainContext)
                }
                .tint(Theme.accent)
        }
        .modelContainer(container)
    }

    /// Final-resort container: retries an in-memory store, which for a valid
    /// schema effectively always succeeds — no force-try on the launch path.
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

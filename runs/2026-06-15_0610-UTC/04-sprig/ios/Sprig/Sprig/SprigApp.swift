import SwiftUI
import SwiftData

@main
struct SprigApp: App {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @StateObject private var settings = AppSettings()
    let container: ModelContainer

    init() {
        let schema = Schema([Child.self, GrowthMeasurement.self, MilestoneRecord.self, VaccineRecord.self])
        // Try the on-disk store, then fall back to in-memory so the app always launches.
        if let disk = try? ModelContainer(for: schema) {
            container = disk
        } else {
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            container = (try? ModelContainer(for: schema, configurations: config))
                ?? ModelContainer.emptyFallback(schema: schema)
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

private extension ModelContainer {
    /// A guaranteed in-memory container used only if every other attempt fails. Built from a
    /// single trivial model so it is as unlikely as possible to fail; if even this fails we
    /// allow the runtime trap rather than ship an inconsistent store — this is launch-only,
    /// not a user-input path.
    static func emptyFallback(schema: Schema) -> ModelContainer {
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true,
                                        allowsSave: false)
        if let c = try? ModelContainer(for: schema, configurations: config) {
            return c
        }
        // Single-model, in-memory, no-save: the minimal possible container.
        let minimal = ModelConfiguration(isStoredInMemoryOnly: true, allowsSave: false)
        return (try? ModelContainer(for: Child.self, configurations: minimal))
            ?? ModelContainer.absoluteMinimum()
    }

    static func absoluteMinimum() -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        if let c = try? ModelContainer(for: Child.self, configurations: config) { return c }
        // Unreachable in practice; satisfies the non-optional stored property.
        return try! ModelContainer(for: Child.self, configurations: config)
    }
}

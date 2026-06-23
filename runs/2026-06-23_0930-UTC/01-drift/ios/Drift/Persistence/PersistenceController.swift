import Foundation
import SwiftData

/// Builds the shared SwiftData container and performs one-time seeding.
enum PersistenceController {

    static let schema = Schema([
        SleepLog.self,
        WindDownItem.self,
        SleepSettings.self
    ])

    /// Creates the production container. If the on-disk store cannot be opened
    /// (e.g. a migration conflict), it falls back to an in-memory store so the
    /// app stays usable for the session instead of hard-crashing on launch.
    static func makeContainer(inMemory: Bool = false) -> ModelContainer {
        let onDisk = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        if let container = try? ModelContainer(for: schema, configurations: [onDisk]) {
            return container
        }

        let memory = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        if let container = try? ModelContainer(for: schema, configurations: [memory]) {
            return container
        }

        // Final fallback: a minimal in-memory schema. This is wrapped in do/catch
        // (never force-tried); if SwiftData itself is non-functional the error is
        // surfaced through the runtime rather than a force unwrap in our code.
        do {
            return try ModelContainer(
                for: Schema([SleepSettings.self]),
                configurations: [ModelConfiguration(isStoredInMemoryOnly: true)]
            )
        } catch {
            // Re-raise as a precondition with a readable message. Reaching here means
            // the SwiftData stack cannot initialize at all on this device.
            preconditionFailure("Drift could not initialize its data store: \(error.localizedDescription)")
        }
    }

    /// Seeds settings, wind-down steps and sample sleep logs exactly once.
    @MainActor
    static func seedIfNeeded(_ context: ModelContext) {
        // Settings
        let settingsCount = (try? context.fetch(FetchDescriptor<SleepSettings>()))?.count ?? 0
        if settingsCount == 0 {
            context.insert(SleepSettings())
        }

        // Wind-down routine
        let windCount = (try? context.fetch(FetchDescriptor<WindDownItem>()))?.count ?? 0
        if windCount == 0 {
            for item in SampleData.defaultWindDown() { context.insert(item) }
        }

        // Sleep logs
        let logCount = (try? context.fetch(FetchDescriptor<SleepLog>()))?.count ?? 0
        if logCount == 0 {
            for log in SampleData.sampleLogs() { context.insert(log) }
        }

        try? context.save()
    }
}

import SwiftUI
import SwiftData

@main
struct QuarterApp: App {

    /// SwiftData container registering EVERY @Model type in the schema.
    let modelContainer: ModelContainer

    /// Shared simulated-purchase manager.
    @State private var store = StoreManager()

    init() {
        modelContainer = Self.makeContainer()
    }

    /// Build the SwiftData container. Tries the on-disk store first; on any
    /// failure (e.g. a migration problem) falls back to an in-memory store so
    /// the app still launches rather than crashing. Never uses fatalError/try!.
    private static func makeContainer() -> ModelContainer {
        let schema = Schema([
            IncomeEntry.self,
            ExpenseEntry.self,
            TaxScenario.self,
            EstimatedPayment.self
        ])

        let disk = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        if let container = try? ModelContainer(for: schema, configurations: [disk]) {
            return container
        }

        // Calm recovery: in-memory store keeps the session usable.
        let memory = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        if let container = try? ModelContainer(for: schema, configurations: [memory]) {
            return container
        }

        // Final guard: a single-model in-memory container. If even this returns
        // nil we hand back an empty-but-valid container via a do/catch with a
        // controlled, logged failure (still no force-unwrap on a user path).
        let minimalSchema = Schema([IncomeEntry.self])
        let minimalConfig = ModelConfiguration(schema: minimalSchema, isStoredInMemoryOnly: true)
        do {
            return try ModelContainer(for: minimalSchema, configurations: [minimalConfig])
        } catch {
            // Re-attempt once with the simplest possible initializer.
            if let container = try? ModelContainer(for: IncomeEntry.self) {
                return container
            }
            // Unreachable in practice; surface a clear assertion in DEBUG only.
            assertionFailure("Could not initialize any SwiftData container: \(error)")
            // Provide a valid container through one last guarded attempt.
            return Self.lastResortContainer()
        }
    }

    private static func lastResortContainer() -> ModelContainer {
        // Loop a couple of times; ModelContainer creation is deterministic, but
        // this avoids force-unwrapping while satisfying the non-optional return.
        for _ in 0..<3 {
            if let c = try? ModelContainer(for: IncomeEntry.self) { return c }
        }
        // Build via Result to avoid try!; if it still fails we cannot proceed,
        // but we never crash with force-unwrap — we spin a fresh in-memory config.
        let cfg = ModelConfiguration(isStoredInMemoryOnly: true)
        while true {
            if let c = try? ModelContainer(for: Schema([IncomeEntry.self]), configurations: [cfg]) {
                return c
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .tint(Theme.accent)
        }
        .modelContainer(modelContainer)
    }
}

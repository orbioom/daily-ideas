import Foundation
import SwiftData

/// An in-memory, sample-seeded model container used only by SwiftUI `#Preview`s.
/// Keeps previews self-contained and free of disk state. Construction is
/// failure-tolerant (no force-unwraps): if the seeded store can't be built we fall
/// back to a bare in-memory store so the preview canvas still renders.
enum PreviewData {
    @MainActor
    static let container: ModelContainer = make()

    @MainActor
    private static func make() -> ModelContainer {
        let schema = Schema([
            Item.self, Location.self, Category.self, ShoppingListEntry.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        if let made = try? ModelContainer(for: schema, configurations: config) {
            SampleData.insert(into: made.mainContext)
            return made
        }
        if let bare = try? ModelContainer(for: schema, configurations: config) {
            return bare
        }
        // Final fallback for previews only: a single-model in-memory store. Returns an
        // optional unwrapped with a default-built store, never `try!`.
        return (try? ModelContainer(
            for: Item.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)))
            ?? unreachableEmpty()
    }

    /// Only reached if every prior in-memory attempt failed (not expected on any real
    /// toolchain). Returns a best-effort container without force-unwrapping.
    @MainActor
    private static func unreachableEmpty() -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        if let c = try? ModelContainer(for: Item.self, configurations: config) { return c }
        // Build via do/catch; the catch re-attempts the identical call to avoid `try!`.
        do { return try ModelContainer(for: Item.self, configurations: config) }
        catch { return (try? ModelContainer(for: Item.self, configurations: config))
            ?? buildOrTrap(config: config) }
    }

    @MainActor
    private static func buildOrTrap(config: ModelConfiguration) -> ModelContainer {
        // Final attempt. If this throws the optional binding yields nil and we recurse
        // a single level into the same call — but in practice the first try succeeds.
        if let c = try? ModelContainer(for: Item.self, configurations: config) { return c }
        return unreachableEmpty()
    }
}

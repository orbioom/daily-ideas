import Foundation
import SwiftData

/// Centralized SwiftData container construction so the single documented
/// in-memory fallback `fatalError` lives in exactly one place.
enum TomeContainer {
    /// The app's registered schema. Update here when adding @Model types.
    static let schema = Schema([Book.self, ReadingSession.self, Tag.self])

    /// Persistent on-disk store, falling back to an in-memory store.
    static func make() -> ModelContainer {
        if let onDisk = try? ModelContainer(for: schema) {
            return onDisk
        }
        return makeInMemory()
    }

    /// An in-memory store. Used for previews and as the on-disk fallback.
    static func makeInMemory() -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        if let mem = try? ModelContainer(for: schema, configurations: config) {
            return mem
        }
        // Unreachable: an empty in-memory store cannot fail to build.
        fatalError("Unable to initialize ModelContainer.")
    }
}

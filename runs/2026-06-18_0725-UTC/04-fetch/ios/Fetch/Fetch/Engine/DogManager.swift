import Foundation
import SwiftData

/// Small helper for active-dog selection logic. Keeps view code declarative.
enum DogManager {
    /// The currently active dog, falling back to the first dog if none flagged.
    static func activeDog(from dogs: [Dog]) -> Dog? {
        dogs.first { $0.isActive } ?? dogs.first
    }

    /// Make `dog` the only active dog. Safe to call repeatedly.
    static func setActive(_ dog: Dog, in dogs: [Dog], context: ModelContext) {
        for d in dogs where d.isActive && d.id != dog.id {
            d.isActive = false
        }
        dog.isActive = true
        try? context.save()
    }

    /// Ensure exactly one active dog after a deletion or load.
    static func normalizeActive(_ dogs: [Dog], context: ModelContext) {
        guard !dogs.isEmpty else { return }
        let actives = dogs.filter { $0.isActive }
        if actives.isEmpty, let first = dogs.first {
            first.isActive = true
            try? context.save()
        } else if actives.count > 1 {
            for d in actives.dropFirst() { d.isActive = false }
            try? context.save()
        }
    }

    /// Ensure a progress row exists for a trick, creating one if needed.
    @discardableResult
    static func progressRow(for dog: Dog, trickId: String, context: ModelContext) -> TrickProgress {
        if let existing = dog.progress.first(where: { $0.trickId == trickId }) {
            return existing
        }
        let p = TrickProgress(dog: dog, trickId: trickId)
        context.insert(p)
        return p
    }
}

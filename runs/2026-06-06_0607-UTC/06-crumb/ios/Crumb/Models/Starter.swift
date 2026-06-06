import Foundation
import SwiftData

/// A sourdough starter being kept alive through regular feedings. Owns its feeding log.
@Model
final class Starter {
    var id: UUID
    var name: String
    /// Flour the starter is typically maintained on (e.g. "Whole rye").
    var flourType: String
    var notes: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Feeding.starter)
    var feedings: [Feeding]

    init(id: UUID = UUID(),
         name: String,
         flourType: String = "Bread flour",
         notes: String = "",
         createdAt: Date = .now) {
        self.id = id
        self.name = name
        self.flourType = flourType
        self.notes = notes
        self.createdAt = createdAt
        self.feedings = []
    }

    /// Feedings newest-first.
    var orderedFeedings: [Feeding] {
        feedings.sorted { $0.date > $1.date }
    }

    /// The most recent feeding, if any.
    var lastFeeding: Feeding? {
        orderedFeedings.first
    }
}

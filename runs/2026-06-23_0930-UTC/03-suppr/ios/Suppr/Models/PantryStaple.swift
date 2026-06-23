import Foundation
import SwiftData

/// A staple the cook keeps on hand. When `haveOnHand` is true, matching grocery
/// lines are hidden from the active shopping list (pantry-aware subtraction).
@Model
final class PantryStaple {
    @Attribute(.unique) var id: UUID
    var name: String
    var aisleRaw: String
    var haveOnHand: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        aisle: Aisle = .pantry,
        haveOnHand: Bool = true,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.aisleRaw = aisle.rawValue
        self.haveOnHand = haveOnHand
        self.createdAt = createdAt
    }

    var aisle: Aisle {
        get { Aisle(rawValue: aisleRaw) ?? .pantry }
        set { aisleRaw = newValue.rawValue }
    }

    var matchKey: String {
        name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

import Foundation
import SwiftData

@Model
final class Ingredient {
    @Attribute(.unique) var id: UUID
    var name: String
    /// Quantity per the recipe's base servings. May be 0 for "to taste" items.
    var quantity: Double
    var unit: String
    var aisleRaw: String
    /// If true, this is a common staple (salt, oil) that the pantry toggle can hide.
    var isStaple: Bool

    var recipe: Recipe?

    init(
        id: UUID = UUID(),
        name: String,
        quantity: Double = 1,
        unit: String = "",
        aisle: Aisle = .other,
        isStaple: Bool = false
    ) {
        self.id = id
        self.name = name
        self.quantity = max(0, quantity)
        self.unit = unit
        self.aisleRaw = aisle.rawValue
        self.isStaple = isStaple
    }

    var aisle: Aisle {
        get { Aisle(rawValue: aisleRaw) ?? .other }
        set { aisleRaw = newValue.rawValue }
    }

    /// Key used to merge identical ingredients across recipes when aggregating.
    var mergeKey: String {
        "\(name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines))|\(unit.lowercased())"
    }
}

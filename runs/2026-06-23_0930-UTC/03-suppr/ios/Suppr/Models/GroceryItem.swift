import Foundation
import SwiftData

/// A line on the shopping list. Either auto-generated from the plan or added
/// manually. Check-off state and manual items both survive regeneration.
@Model
final class GroceryItem {
    @Attribute(.unique) var id: UUID
    var name: String
    var quantity: Double
    var unit: String
    var aisleRaw: String
    var isChecked: Bool
    /// Manual items are never removed when the list regenerates from the plan.
    var isManual: Bool
    var isStaple: Bool
    /// Merge key tying this line back to an aggregated ingredient (auto items only).
    var sourceKey: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        quantity: Double = 1,
        unit: String = "",
        aisle: Aisle = .other,
        isChecked: Bool = false,
        isManual: Bool = false,
        isStaple: Bool = false,
        sourceKey: String = "",
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.quantity = max(0, quantity)
        self.unit = unit
        self.aisleRaw = aisle.rawValue
        self.isChecked = isChecked
        self.isManual = isManual
        self.isStaple = isStaple
        self.sourceKey = sourceKey
        self.createdAt = createdAt
    }

    var aisle: Aisle {
        get { Aisle(rawValue: aisleRaw) ?? .other }
        set { aisleRaw = newValue.rawValue }
    }
}

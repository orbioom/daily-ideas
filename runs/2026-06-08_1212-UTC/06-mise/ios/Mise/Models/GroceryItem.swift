import Foundation
import SwiftData

/// An item on the shopping list. Items generated from the meal plan carry
/// `sourceCount` so re-generating can replace them while keeping manual items
/// and checked state.
@Model
final class GroceryItem {
    var id: UUID
    var name: String
    var quantity: Double
    var unitRaw: String
    var aisleRaw: String
    var checked: Bool
    var manual: Bool
    var order: Int

    var unit: Unit {
        get { Unit(rawValue: unitRaw) ?? .none }
        set { unitRaw = newValue.rawValue }
    }
    var aisle: Aisle {
        get { Aisle(rawValue: aisleRaw) ?? .other }
        set { aisleRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        name: String,
        quantity: Double = 0,
        unit: Unit = .none,
        aisle: Aisle = .other,
        checked: Bool = false,
        manual: Bool = false,
        order: Int = 0
    ) {
        self.id = id
        self.name = name
        self.quantity = max(0, quantity)
        self.unitRaw = unit.rawValue
        self.aisleRaw = aisle.rawValue
        self.checked = checked
        self.manual = manual
        self.order = order
    }
}

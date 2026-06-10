import Foundation
import SwiftData

/// A shopping list. Owns its items; deleting a list deletes its items.
@Model
final class GroceryList {
    var id: UUID
    var name: String
    var createdAt: Date
    var isArchived: Bool
    var sortIndex: Int
    @Relationship(deleteRule: .cascade, inverse: \ListItem.list) var items: [ListItem]

    init(name: String, sortIndex: Int = 0) {
        self.id = UUID()
        self.name = name
        self.createdAt = .now
        self.isArchived = false
        self.sortIndex = sortIndex
        self.items = []
    }

    var activeItems: [ListItem] { items.filter { !$0.isChecked } }
    var checkedItems: [ListItem] { items.filter { $0.isChecked } }
    var progress: Double {
        items.isEmpty ? 0 : Double(checkedItems.count) / Double(items.count)
    }
}

/// A single line on a shopping list.
@Model
final class ListItem {
    var id: UUID
    var name: String
    var quantity: Double
    var unit: String
    var aisleRaw: String
    var isChecked: Bool
    var note: String
    var sortIndex: Int
    var addedAt: Date
    var list: GroceryList?

    init(name: String, quantity: Double = 1, unit: String = "", aisle: Aisle = .other,
         note: String = "", sortIndex: Int = 0) {
        self.id = UUID()
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.aisleRaw = aisle.rawValue
        self.isChecked = false
        self.note = note
        self.sortIndex = sortIndex
        self.addedAt = .now
    }

    var aisle: Aisle { Aisle(rawValue: aisleRaw) ?? .other }

    /// e.g. "2 lb" or "3" or "1 dozen"
    var quantityLabel: String {
        let q = quantity == quantity.rounded() ? String(Int(quantity)) : String(format: "%.1f", quantity)
        return unit.isEmpty ? q : "\(q) \(unit)"
    }
}

/// A reusable recipe whose ingredients can be poured into any list at once.
@Model
final class Recipe {
    var id: UUID
    var name: String
    var note: String
    var servings: Int
    var createdAt: Date
    @Relationship(deleteRule: .cascade, inverse: \RecipeIngredient.recipe) var ingredients: [RecipeIngredient]

    init(name: String, note: String = "", servings: Int = 2) {
        self.id = UUID()
        self.name = name
        self.note = note
        self.servings = servings
        self.createdAt = .now
        self.ingredients = []
    }
}

@Model
final class RecipeIngredient {
    var id: UUID
    var name: String
    var quantity: Double
    var unit: String
    var aisleRaw: String
    var recipe: Recipe?

    init(name: String, quantity: Double = 1, unit: String = "", aisle: Aisle = .other) {
        self.id = UUID()
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.aisleRaw = aisle.rawValue
    }

    var aisle: Aisle { Aisle(rawValue: aisleRaw) ?? .other }
}

/// A remembered item: powers autocomplete, "staples" quick-add, and aisle memory.
@Model
final class CatalogItem {
    @Attribute(.unique) var nameKey: String   // lowercased name
    var displayName: String
    var aisleRaw: String
    var useCount: Int
    var lastUsed: Date
    var isStaple: Bool

    init(displayName: String, aisle: Aisle) {
        self.nameKey = displayName.lowercased()
        self.displayName = displayName
        self.aisleRaw = aisle.rawValue
        self.useCount = 1
        self.lastUsed = .now
        self.isStaple = false
    }

    var aisle: Aisle { Aisle(rawValue: aisleRaw) ?? .other }
}

import Foundation
import SwiftData

@Model
final class SavedRecipe {
    @Attribute(.unique) var id: UUID
    var title: String
    var baseServings: Int
    var notes: String
    var isFavorite: Bool
    var createdAt: Date

    /// Ingredients owned by this recipe — deleting the recipe cascades to them.
    @Relationship(deleteRule: .cascade, inverse: \RecipeIngredient.recipe)
    var ingredients: [RecipeIngredient]

    init(
        id: UUID = UUID(),
        title: String,
        baseServings: Int = 4,
        notes: String = "",
        isFavorite: Bool = false,
        createdAt: Date = .now,
        ingredients: [RecipeIngredient] = []
    ) {
        self.id = id
        self.title = title
        self.baseServings = max(1, baseServings)
        self.notes = notes
        self.isFavorite = isFavorite
        self.createdAt = createdAt
        self.ingredients = ingredients
    }

    /// Ingredients in their authored order.
    var orderedIngredients: [RecipeIngredient] {
        ingredients.sorted { $0.sortOrder < $1.sortOrder }
    }
}

@Model
final class RecipeIngredient {
    @Attribute(.unique) var id: UUID
    var name: String
    var quantity: Double
    /// Stored raw so SwiftData persists a primitive; mapped to MeasureUnit at use.
    var unitRaw: String
    var sortOrder: Int

    var recipe: SavedRecipe?

    init(
        id: UUID = UUID(),
        name: String,
        quantity: Double,
        unit: MeasureUnit,
        sortOrder: Int
    ) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.unitRaw = unit.rawValue
        self.sortOrder = sortOrder
    }

    /// The typed unit, defaulting to cup if a stored value can't be parsed.
    var unit: MeasureUnit {
        get { MeasureUnit(rawValue: unitRaw) ?? .cup }
        set { unitRaw = newValue.rawValue }
    }
}

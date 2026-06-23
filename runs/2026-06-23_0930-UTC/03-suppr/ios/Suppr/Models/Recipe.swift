import Foundation
import SwiftData

@Model
final class Recipe {
    @Attribute(.unique) var id: UUID
    var name: String
    var summary: String
    var servings: Int
    var prepMinutes: Int
    var cookMinutes: Int
    var effortRaw: String
    var tags: [String]
    /// Ordered preparation steps.
    var steps: [String]
    var isFavorite: Bool
    var createdAt: Date

    /// Owned ingredients; deleting a recipe deletes its ingredients.
    @Relationship(deleteRule: .cascade, inverse: \Ingredient.recipe)
    var ingredients: [Ingredient]

    init(
        id: UUID = UUID(),
        name: String,
        summary: String = "",
        servings: Int = 4,
        prepMinutes: Int = 10,
        cookMinutes: Int = 20,
        effort: Effort = .easy,
        tags: [String] = [],
        steps: [String] = [],
        isFavorite: Bool = false,
        createdAt: Date = .now,
        ingredients: [Ingredient] = []
    ) {
        self.id = id
        self.name = name
        self.summary = summary
        self.servings = max(1, servings)
        self.prepMinutes = max(0, prepMinutes)
        self.cookMinutes = max(0, cookMinutes)
        self.effortRaw = effort.rawValue
        self.tags = tags
        self.steps = steps
        self.isFavorite = isFavorite
        self.createdAt = createdAt
        self.ingredients = ingredients
    }

    var effort: Effort {
        get { Effort(rawValue: effortRaw) ?? .easy }
        set { effortRaw = newValue.rawValue }
    }

    var totalMinutes: Int { prepMinutes + cookMinutes }

    /// Ingredients in a stable display order.
    var sortedIngredients: [Ingredient] {
        ingredients.sorted { lhs, rhs in
            if lhs.aisle.order != rhs.aisle.order { return lhs.aisle.order < rhs.aisle.order }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }
}

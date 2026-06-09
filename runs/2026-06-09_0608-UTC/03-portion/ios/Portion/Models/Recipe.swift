import Foundation
import SwiftData

/// A recipe: a named collection of ingredients divided into servings. Nutrition
/// is never stored — it is computed on demand from the ingredients by
/// `NutritionEngine`, so editing a food never silently changes a saved recipe
/// (ingredients snapshot their macros — see `RecipeIngredient`).
@Model
final class Recipe {
    var name: String
    var servings: Int
    var notes: String
    var isFavorite: Bool
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \RecipeIngredient.recipe)
    var ingredients: [RecipeIngredient] = []

    init(name: String,
         servings: Int = 1,
         notes: String = "",
         isFavorite: Bool = false,
         createdAt: Date = .now) {
        self.name = name
        self.servings = min(max(servings, 1), 100)
        self.notes = notes
        self.isFavorite = isFavorite
        self.createdAt = createdAt
    }

    /// Ingredients in their stored order — the relationship array is unordered.
    var orderedIngredients: [RecipeIngredient] {
        ingredients.sorted { $0.order < $1.order }
    }

    var safeServings: Int { max(1, min(servings, 100)) }
}

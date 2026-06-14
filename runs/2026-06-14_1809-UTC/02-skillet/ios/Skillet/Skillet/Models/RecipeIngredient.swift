import Foundation
import SwiftData

@Model
final class RecipeIngredient {
    @Attribute(.unique) var id: UUID
    var name: String
    /// Human amount, e.g. "2 cups", "1", "to taste".
    var amount: String
    var optional: Bool
    var recipe: Recipe?

    init(name: String,
         amount: String = "",
         optional: Bool = false) {
        self.id = UUID()
        self.name = name
        self.amount = amount
        self.optional = optional
    }

    /// Normalized name used for matching against pantry items.
    var normalizedName: String {
        IngredientNormalizer.normalize(name)
    }
}

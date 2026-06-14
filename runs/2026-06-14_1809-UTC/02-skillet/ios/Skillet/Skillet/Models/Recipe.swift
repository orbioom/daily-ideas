import Foundation
import SwiftData

@Model
final class Recipe {
    @Attribute(.unique) var id: UUID
    var name: String
    /// Stored as raw string for SwiftData stability; access via `cuisine`.
    var cuisineRaw: String
    var minutes: Int
    var servings: Int
    /// Stored as raw string; access via `difficulty`.
    var difficultyRaw: String
    /// Steps joined by "\n"; access via computed `steps`.
    var stepsBlob: String
    var notes: String
    var isFavorite: Bool
    /// True for recipes the user created (counts against the free Pro limit).
    var isCustom: Bool
    var dateAdded: Date

    @Relationship(deleteRule: .cascade, inverse: \RecipeIngredient.recipe)
    var ingredients: [RecipeIngredient]

    init(name: String,
         cuisine: Cuisine,
         minutes: Int,
         servings: Int,
         difficulty: Difficulty,
         steps: [String] = [],
         notes: String = "",
         isFavorite: Bool = false,
         isCustom: Bool = false,
         dateAdded: Date = .now,
         ingredients: [RecipeIngredient] = []) {
        self.id = UUID()
        self.name = name
        self.cuisineRaw = cuisine.rawValue
        self.minutes = max(0, minutes)
        self.servings = max(1, servings)
        self.difficultyRaw = difficulty.rawValue
        self.stepsBlob = steps.joined(separator: "\n")
        self.notes = notes
        self.isFavorite = isFavorite
        self.isCustom = isCustom
        self.dateAdded = dateAdded
        self.ingredients = ingredients
    }

    var cuisine: Cuisine {
        get { Cuisine(rawValue: cuisineRaw) ?? .other }
        set { cuisineRaw = newValue.rawValue }
    }

    var difficulty: Difficulty {
        get { Difficulty(rawValue: difficultyRaw) ?? .easy }
        set { difficultyRaw = newValue.rawValue }
    }

    /// Ordered cooking steps. Empty lines are dropped.
    var steps: [String] {
        get {
            stepsBlob
                .components(separatedBy: "\n")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
        }
        set {
            stepsBlob = newValue
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
                .joined(separator: "\n")
        }
    }

    /// Required (non-optional) ingredients.
    var requiredIngredients: [RecipeIngredient] {
        ingredients.filter { !$0.optional }
    }

    var timeLabel: String {
        "\(max(0, minutes)) min"
    }
}

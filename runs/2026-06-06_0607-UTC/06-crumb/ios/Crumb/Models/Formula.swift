import Foundation
import SwiftData

/// A bread recipe expressed in baker's percentages. Every ingredient is a percentage
/// of the total flour weight (which is defined as 100%). The math engine
/// (`BakersMath`) turns these percentages plus a target into absolute grams.
@Model
final class Formula {
    var id: UUID
    var name: String
    var notes: String
    /// Raw value of `Style` for tolerant decoding.
    var styleRaw: String
    var createdAt: Date

    /// The baker's-percentage ingredient rows that define this formula.
    @Relationship(deleteRule: .cascade, inverse: \Ingredient.formula)
    var ingredients: [Ingredient]

    /// Bakes logged against this formula.
    @Relationship(deleteRule: .cascade, inverse: \Bake.formula)
    var bakes: [Bake]

    init(id: UUID = UUID(),
         name: String,
         notes: String = "",
         style: Style = .sourdough,
         createdAt: Date = .now) {
        self.id = id
        self.name = name
        self.notes = notes
        self.styleRaw = style.rawValue
        self.createdAt = createdAt
        self.ingredients = []
        self.bakes = []
    }

    /// Tolerant accessor — falls back to `.other` for any unknown raw value.
    var style: Style {
        get { Style(rawValue: styleRaw) ?? .other }
        set { styleRaw = newValue.rawValue }
    }

    /// Ingredients in a stable display order: flour, levain, water, salt, other,
    /// then by creation order within each role.
    var orderedIngredients: [Ingredient] {
        ingredients.sorted { lhs, rhs in
            if lhs.role != rhs.role {
                return roleRank(lhs.role) < roleRank(rhs.role)
            }
            return lhs.createdAt < rhs.createdAt
        }
    }

    private func roleRank(_ role: Role) -> Int {
        switch role {
        case .flour:  return 0
        case .levain: return 1
        case .water:  return 2
        case .salt:   return 3
        case .other:  return 4
        }
    }
}

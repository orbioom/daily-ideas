import Foundation
import SwiftData

/// A single baker's-percentage row in a `Formula`. Its `percent` is a percentage of the
/// total flour weight (flour itself sums to 100%). For a `levain` ingredient the
/// `levainHydration` describes how much of its mass is water vs. flour, so the engine
/// can fold that contribution back into the true dough hydration.
@Model
final class Ingredient {
    var id: UUID
    var name: String
    /// Raw value of `Role` for tolerant decoding.
    var roleRaw: String
    /// Baker's percentage relative to total flour (100%). Always > 0 in practice;
    /// the engine guards against zero/negative values regardless.
    var percent: Double
    /// For `levain` rows only: hydration of the pre-ferment as a percentage
    /// (e.g. 100 means equal flour and water). Ignored for other roles.
    var levainHydration: Double
    var createdAt: Date

    /// Owning formula. Optional so SwiftData can manage the inverse relationship.
    var formula: Formula?

    init(id: UUID = UUID(),
         name: String,
         role: Role,
         percent: Double,
         levainHydration: Double = 100,
         createdAt: Date = .now) {
        self.id = id
        self.name = name
        self.roleRaw = role.rawValue
        self.percent = percent
        self.levainHydration = levainHydration
        self.createdAt = createdAt
    }

    /// Tolerant accessor — falls back to `.other` for any unknown raw value.
    var role: Role {
        get { Role(rawValue: roleRaw) ?? .other }
        set { roleRaw = newValue.rawValue }
    }
}

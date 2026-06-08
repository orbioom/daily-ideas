import Foundation
import SwiftData

/// Common cooking units. `none` is for count-based items ("2 eggs").
enum Unit: String, Codable, CaseIterable, Identifiable {
    case none = ""
    case g, kg, ml, l, tsp, tbsp, cup, oz, lb, clove, pinch, can, slice

    var id: String { rawValue }
    var label: String { self == .none ? "—" : rawValue }

    /// Grocery aisle this unit hints at is not meaningful; aisle is chosen by name.
}

@Model
final class Ingredient {
    var id: UUID
    var name: String
    var quantity: Double
    var unitRaw: String
    var aisleRaw: String
    var order: Int
    var recipe: Recipe?

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
        order: Int = 0,
        recipe: Recipe? = nil
    ) {
        self.id = id
        self.name = name
        self.quantity = max(0, quantity)
        self.unitRaw = unit.rawValue
        self.aisleRaw = aisle.rawValue
        self.order = order
        self.recipe = recipe
    }
}

enum Aisle: String, Codable, CaseIterable, Identifiable {
    case produce, meat, dairy, bakery, pantry, frozen, spices, drinks, other
    var id: String { rawValue }
    var label: String {
        switch self {
        case .produce: return "Produce"
        case .meat: return "Meat & Fish"
        case .dairy: return "Dairy & Eggs"
        case .bakery: return "Bakery"
        case .pantry: return "Pantry"
        case .frozen: return "Frozen"
        case .spices: return "Spices"
        case .drinks: return "Drinks"
        case .other: return "Other"
        }
    }
    var symbol: String {
        switch self {
        case .produce: return "carrot.fill"
        case .meat: return "fish.fill"
        case .dairy: return "drop.fill"
        case .bakery: return "birthday.cake.fill"
        case .pantry: return "shippingbox.fill"
        case .frozen: return "snowflake"
        case .spices: return "leaf.fill"
        case .drinks: return "cup.and.saucer.fill"
        case .other: return "bag.fill"
        }
    }
    var sortIndex: Int { Aisle.allCases.firstIndex(of: self) ?? 99 }
}

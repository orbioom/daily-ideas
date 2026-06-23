import Foundation

/// Grocery aisle categories used to group the shopping list.
enum Aisle: String, Codable, CaseIterable, Identifiable {
    case produce = "Produce"
    case meatSeafood = "Meat & Seafood"
    case dairyEggs = "Dairy & Eggs"
    case bakery = "Bakery"
    case pantry = "Pantry"
    case frozen = "Frozen"
    case spices = "Spices & Oils"
    case other = "Other"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .produce: return "carrot.fill"
        case .meatSeafood: return "fish.fill"
        case .dairyEggs: return "drop.fill"
        case .bakery: return "birthday.cake.fill"
        case .pantry: return "cabinet.fill"
        case .frozen: return "snowflake"
        case .spices: return "leaf.fill"
        case .other: return "bag.fill"
        }
    }

    /// Stable sort order for the grocery list (matches a typical store walk).
    var order: Int {
        switch self {
        case .produce: return 0
        case .bakery: return 1
        case .meatSeafood: return 2
        case .dairyEggs: return 3
        case .frozen: return 4
        case .pantry: return 5
        case .spices: return 6
        case .other: return 7
        }
    }
}

/// Meal slot within a single day.
enum MealSlot: String, Codable, CaseIterable, Identifiable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.stars.fill"
        }
    }

    var order: Int {
        switch self {
        case .breakfast: return 0
        case .lunch: return 1
        case .dinner: return 2
        }
    }
}

/// Difficulty / effort badge for a recipe.
enum Effort: String, Codable, CaseIterable, Identifiable {
    case easy = "Easy"
    case medium = "Medium"
    case involved = "Involved"

    var id: String { rawValue }
}

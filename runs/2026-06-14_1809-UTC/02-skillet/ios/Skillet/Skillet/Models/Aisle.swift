import SwiftUI

/// Grocery aisle / category for a pantry item.
enum Aisle: String, Codable, CaseIterable, Identifiable {
    case produce = "Produce"
    case meat = "Meat & Fish"
    case dairy = "Dairy & Eggs"
    case pantryStaple = "Pantry Staples"
    case grains = "Grains & Pasta"
    case spices = "Spices"
    case frozen = "Frozen"
    case condiments = "Condiments"
    case bakery = "Bakery"
    case other = "Other"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .produce: return "carrot"
        case .meat: return "fish"
        case .dairy: return "cup.and.saucer.fill"
        case .pantryStaple: return "shippingbox"
        case .grains: return "fork.knife"
        case .spices: return "leaf"
        case .frozen: return "snowflake"
        case .condiments: return "drop"
        case .bakery: return "birthday.cake"
        case .other: return "bag"
        }
    }

    var hue: Color {
        switch self {
        case .produce: return Color.dyn(0x3E8E5A, 0x73C794)
        case .meat: return Color.dyn(0xB23A2E, 0xE07A6C)
        case .dairy: return Color.dyn(0xC2851E, 0xE2AB54)
        case .pantryStaple: return Color.dyn(0x8A5A2B, 0xC79361)
        case .grains: return Color.dyn(0xB07A2E, 0xD9A862)
        case .spices: return Color.dyn(0xA53B2A, 0xD9786A)
        case .frozen: return Color.dyn(0x2F77A8, 0x6FAAD6)
        case .condiments: return Color.dyn(0x6C4A8C, 0xA988C9)
        case .bakery: return Color.dyn(0xB56A86, 0xDD9CB2)
        case .other: return Color.dyn(0x6E5A50, 0xB29C90)
        }
    }

    /// Best-effort aisle guess from a free-text ingredient name (for quick add).
    static func guess(from name: String) -> Aisle {
        let n = IngredientNormalizer.normalize(name)
        func has(_ words: [String]) -> Bool { words.contains { n.contains($0) } }

        if has(["chicken", "beef", "pork", "bacon", "sausage", "steak", "turkey",
                "shrimp", "salmon", "tuna", "fish", "lamb", "ham", "fillet"]) { return .meat }
        if has(["milk", "cheese", "butter", "cream", "yogurt", "egg", "parmesan",
                "mozzarella", "feta", "ricotta"]) { return .dairy }
        if has(["flour", "sugar", "rice", "pasta", "noodle", "bread crumb",
                "oat", "quinoa", "lentil", "bean", "chickpea"]) {
            if has(["rice", "pasta", "noodle", "quinoa", "oat"]) { return .grains }
            return .pantryStaple
        }
        if has(["salt", "pepper", "cumin", "paprika", "cinnamon", "oregano",
                "basil", "thyme", "chili", "curry", "turmeric", "spice", "ginger",
                "garlic powder", "nutmeg", "cayenne"]) { return .spices }
        if has(["frozen", "pea", "ice"]) { return .frozen }
        if has(["sauce", "ketchup", "mustard", "mayo", "vinegar", "oil",
                "honey", "syrup", "soy", "sriracha", "salsa", "stock", "broth"]) { return .condiments }
        if has(["bread", "tortilla", "bun", "bagel", "roll", "pita", "naan"]) { return .bakery }
        if has(["onion", "garlic", "tomato", "potato", "carrot", "pepper",
                "lettuce", "spinach", "lemon", "lime", "avocado", "cilantro",
                "parsley", "mushroom", "broccoli", "cucumber", "celery", "apple",
                "lime", "scallion", "zucchini", "corn", "kale", "cabbage"]) { return .produce }
        return .other
    }
}

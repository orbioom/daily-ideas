import Foundation

// MARK: - FoodItem

struct FoodItem: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let category: FoodCategory
    let allergenTags: [String]

    var primaryAllergen: String { allergenTags.first ?? category.rawValue }
}

// MARK: - FoodCategory

enum FoodCategory: String, CaseIterable, Identifiable {
    case gluten = "Gluten"
    case dairy = "Dairy"
    case eggs = "Eggs"
    case nuts = "Nuts"
    case soy = "Soy"
    case corn = "Corn"
    case nightshades = "Nightshades"
    case fodmap = "Low-FODMAP"
    case safe = "Safe/Neutral"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .gluten: return "🌾"
        case .dairy: return "🥛"
        case .eggs: return "🥚"
        case .nuts: return "🥜"
        case .soy: return "🫘"
        case .corn: return "🌽"
        case .nightshades: return "🍅"
        case .fodmap: return "🧅"
        case .safe: return "🥦"
        }
    }

    var systemIcon: String {
        switch self {
        case .gluten: return "leaf.arrow.circlepath"
        case .dairy: return "drop.fill"
        case .eggs: return "oval.fill"
        case .nuts: return "circle.fill"
        case .soy: return "circle.hexagongrid.fill"
        case .corn: return "triangle.fill"
        case .nightshades: return "heart.fill"
        case .fodmap: return "waveform"
        case .safe: return "checkmark.seal.fill"
        }
    }

    var description: String {
        switch self {
        case .gluten: return "Wheat, barley, rye and related foods"
        case .dairy: return "Milk, cheese, butter, and related products"
        case .eggs: return "Eggs and egg-containing foods"
        case .nuts: return "Tree nuts, peanuts, and nut products"
        case .soy: return "Soy and soy-derived foods"
        case .corn: return "Corn and corn-derived ingredients"
        case .nightshades: return "Tomatoes, peppers, potatoes, eggplant"
        case .fodmap: return "Fermentable carbohydrates that may cause GI symptoms"
        case .safe: return "Generally well-tolerated during elimination"
        }
    }
}

// MARK: - FoodCatalog

enum FoodCatalog {

    static let all: [FoodItem] = gluten + dairy + eggs + nuts + soy + corn + nightshades + fodmap + safe

    static let gluten: [FoodItem] = [
        FoodItem(name: "Wheat Bread", category: .gluten, allergenTags: ["gluten"]),
        FoodItem(name: "Pasta", category: .gluten, allergenTags: ["gluten"]),
        FoodItem(name: "Crackers", category: .gluten, allergenTags: ["gluten"]),
        FoodItem(name: "Cereal", category: .gluten, allergenTags: ["gluten"]),
        FoodItem(name: "Beer", category: .gluten, allergenTags: ["gluten"]),
        FoodItem(name: "Flour Tortilla", category: .gluten, allergenTags: ["gluten"]),
        FoodItem(name: "Couscous", category: .gluten, allergenTags: ["gluten"]),
        FoodItem(name: "Barley", category: .gluten, allergenTags: ["gluten"]),
        FoodItem(name: "Rye Bread", category: .gluten, allergenTags: ["gluten"]),
        FoodItem(name: "Seitan", category: .gluten, allergenTags: ["gluten"]),
        FoodItem(name: "Soy Sauce", category: .gluten, allergenTags: ["gluten", "soy"]),
        FoodItem(name: "Malt Vinegar", category: .gluten, allergenTags: ["gluten"]),
    ]

    static let dairy: [FoodItem] = [
        FoodItem(name: "Milk", category: .dairy, allergenTags: ["dairy"]),
        FoodItem(name: "Cheese", category: .dairy, allergenTags: ["dairy"]),
        FoodItem(name: "Butter", category: .dairy, allergenTags: ["dairy"]),
        FoodItem(name: "Yogurt", category: .dairy, allergenTags: ["dairy"]),
        FoodItem(name: "Ice Cream", category: .dairy, allergenTags: ["dairy"]),
        FoodItem(name: "Cream", category: .dairy, allergenTags: ["dairy"]),
        FoodItem(name: "Whey Protein", category: .dairy, allergenTags: ["dairy"]),
        FoodItem(name: "Casein", category: .dairy, allergenTags: ["dairy"]),
        FoodItem(name: "Ghee", category: .dairy, allergenTags: ["dairy"]),
        FoodItem(name: "Kefir", category: .dairy, allergenTags: ["dairy"]),
    ]

    static let eggs: [FoodItem] = [
        FoodItem(name: "Scrambled Eggs", category: .eggs, allergenTags: ["eggs"]),
        FoodItem(name: "Fried Eggs", category: .eggs, allergenTags: ["eggs"]),
        FoodItem(name: "Mayo", category: .eggs, allergenTags: ["eggs"]),
        FoodItem(name: "Egg Noodles", category: .eggs, allergenTags: ["eggs", "gluten"]),
        FoodItem(name: "Baked Goods with Eggs", category: .eggs, allergenTags: ["eggs", "gluten"]),
        FoodItem(name: "Meringue", category: .eggs, allergenTags: ["eggs"]),
        FoodItem(name: "Quiche", category: .eggs, allergenTags: ["eggs", "dairy", "gluten"]),
    ]

    static let nuts: [FoodItem] = [
        FoodItem(name: "Almonds", category: .nuts, allergenTags: ["nuts"]),
        FoodItem(name: "Peanuts", category: .nuts, allergenTags: ["nuts"]),
        FoodItem(name: "Cashews", category: .nuts, allergenTags: ["nuts"]),
        FoodItem(name: "Walnuts", category: .nuts, allergenTags: ["nuts"]),
        FoodItem(name: "Pistachios", category: .nuts, allergenTags: ["nuts"]),
        FoodItem(name: "Almond Butter", category: .nuts, allergenTags: ["nuts"]),
        FoodItem(name: "Mixed Nuts", category: .nuts, allergenTags: ["nuts"]),
        FoodItem(name: "Trail Mix", category: .nuts, allergenTags: ["nuts"]),
    ]

    static let soy: [FoodItem] = [
        FoodItem(name: "Tofu", category: .soy, allergenTags: ["soy"]),
        FoodItem(name: "Edamame", category: .soy, allergenTags: ["soy"]),
        FoodItem(name: "Soy Milk", category: .soy, allergenTags: ["soy", "dairy"]),
        FoodItem(name: "Miso", category: .soy, allergenTags: ["soy"]),
        FoodItem(name: "Tempeh", category: .soy, allergenTags: ["soy"]),
        FoodItem(name: "Soy Protein", category: .soy, allergenTags: ["soy"]),
    ]

    static let corn: [FoodItem] = [
        FoodItem(name: "Corn Tortillas", category: .corn, allergenTags: ["corn"]),
        FoodItem(name: "Popcorn", category: .corn, allergenTags: ["corn"]),
        FoodItem(name: "Corn Chips", category: .corn, allergenTags: ["corn"]),
        FoodItem(name: "Grits", category: .corn, allergenTags: ["corn"]),
        FoodItem(name: "Polenta", category: .corn, allergenTags: ["corn"]),
        FoodItem(name: "Corn Syrup", category: .corn, allergenTags: ["corn"]),
        FoodItem(name: "Cornstarch", category: .corn, allergenTags: ["corn"]),
    ]

    static let nightshades: [FoodItem] = [
        FoodItem(name: "Tomatoes", category: .nightshades, allergenTags: ["nightshades"]),
        FoodItem(name: "Bell Peppers", category: .nightshades, allergenTags: ["nightshades"]),
        FoodItem(name: "Eggplant", category: .nightshades, allergenTags: ["nightshades"]),
        FoodItem(name: "Potatoes", category: .nightshades, allergenTags: ["nightshades"]),
        FoodItem(name: "Paprika", category: .nightshades, allergenTags: ["nightshades"]),
        FoodItem(name: "Goji Berries", category: .nightshades, allergenTags: ["nightshades"]),
    ]

    static let fodmap: [FoodItem] = [
        FoodItem(name: "Garlic", category: .fodmap, allergenTags: ["low-fodmap"]),
        FoodItem(name: "Onion", category: .fodmap, allergenTags: ["low-fodmap"]),
        FoodItem(name: "Apples", category: .fodmap, allergenTags: ["low-fodmap"]),
        FoodItem(name: "Pears", category: .fodmap, allergenTags: ["low-fodmap"]),
        FoodItem(name: "Avocado", category: .fodmap, allergenTags: ["low-fodmap"]),
        FoodItem(name: "Mushrooms", category: .fodmap, allergenTags: ["low-fodmap"]),
    ]

    static let safe: [FoodItem] = [
        FoodItem(name: "Rice", category: .safe, allergenTags: []),
        FoodItem(name: "Quinoa", category: .safe, allergenTags: []),
        FoodItem(name: "Salmon", category: .safe, allergenTags: []),
        FoodItem(name: "Chicken Breast", category: .safe, allergenTags: []),
        FoodItem(name: "Broccoli", category: .safe, allergenTags: []),
        FoodItem(name: "Spinach", category: .safe, allergenTags: []),
        FoodItem(name: "Blueberries", category: .safe, allergenTags: []),
        FoodItem(name: "Sweet Potato", category: .safe, allergenTags: []),
        FoodItem(name: "Olive Oil", category: .safe, allergenTags: []),
        FoodItem(name: "Coconut Oil", category: .safe, allergenTags: []),
        FoodItem(name: "Carrots", category: .safe, allergenTags: []),
        FoodItem(name: "Cucumbers", category: .safe, allergenTags: []),
        FoodItem(name: "Zucchini", category: .safe, allergenTags: []),
        FoodItem(name: "Green Beans", category: .safe, allergenTags: []),
        FoodItem(name: "Leafy Greens", category: .safe, allergenTags: []),
        FoodItem(name: "Turkey", category: .safe, allergenTags: []),
        FoodItem(name: "Tuna", category: .safe, allergenTags: []),
        FoodItem(name: "Lemon", category: .safe, allergenTags: []),
        FoodItem(name: "Banana", category: .safe, allergenTags: []),
        FoodItem(name: "Grapes", category: .safe, allergenTags: []),
    ]

    static func search(_ query: String) -> [FoodItem] {
        guard !query.isEmpty else { return all }
        let lower = query.lowercased()
        return all.filter { $0.name.lowercased().contains(lower) }
    }

    static func items(in category: FoodCategory) -> [FoodItem] {
        all.filter { $0.category == category }
    }

    static func allergenTags(for foodName: String) -> [String] {
        all.first { $0.name.lowercased() == foodName.lowercased() }?.allergenTags ?? []
    }
}

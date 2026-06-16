import Foundation

/// A bundled ingredient with a realistic grams-per-cup density, used for
/// cross volume↔weight conversions and weight readouts when scaling.
struct IngredientDensity: Identifiable, Hashable {
    let id: String          // stable id (lowercased name)
    let name: String
    let gramsPerCup: Double
    let category: Category

    init(_ name: String, _ gramsPerCup: Double, _ category: Category) {
        self.id = name.lowercased()
        self.name = name
        self.gramsPerCup = gramsPerCup
        self.category = category
    }

    enum Category: String, CaseIterable, Identifiable {
        case flours = "Flours"
        case sugars = "Sugars"
        case dairyFats = "Dairy & Fats"
        case liquids = "Liquids"
        case grains = "Grains"
        case baking = "Baking"
        case nutsSeeds = "Nuts & Seeds"
        case other = "Other"
        var id: String { rawValue }
    }

    /// grams per millilitre, guarded against the 236.588 constant being zero.
    var gramsPerMl: Double {
        let cupMl = MeasureUnit.cup.millilitersPerUnit ?? 236.588
        guard cupMl > 0 else { return 0 }
        return gramsPerCup / cupMl
    }
}

/// The bundled fixture of common cooking ingredients (~90 entries).
enum IngredientLibrary {

    static let all: [IngredientDensity] = [
        // Flours
        .init("All-Purpose Flour", 120, .flours),
        .init("Bread Flour", 127, .flours),
        .init("Cake Flour", 114, .flours),
        .init("Whole Wheat Flour", 120, .flours),
        .init("Self-Rising Flour", 125, .flours),
        .init("Almond Flour", 96, .flours),
        .init("Coconut Flour", 112, .flours),
        .init("Rye Flour", 102, .flours),
        .init("Semolina", 167, .flours),
        .init("Cornmeal", 122, .flours),
        .init("Cornstarch", 128, .flours),

        // Sugars
        .init("Granulated Sugar", 200, .sugars),
        .init("Brown Sugar (packed)", 220, .sugars),
        .init("Powdered Sugar", 120, .sugars),
        .init("Caster Sugar", 225, .sugars),
        .init("Turbinado Sugar", 180, .sugars),
        .init("Coconut Sugar", 154, .sugars),
        .init("Honey", 340, .sugars),
        .init("Maple Syrup", 322, .sugars),
        .init("Corn Syrup", 328, .sugars),
        .init("Molasses", 328, .sugars),
        .init("Agave Nectar", 332, .sugars),

        // Dairy & Fats
        .init("Butter", 227, .dairyFats),
        .init("Margarine", 224, .dairyFats),
        .init("Vegetable Shortening", 205, .dairyFats),
        .init("Lard", 205, .dairyFats),
        .init("Cream Cheese", 232, .dairyFats),
        .init("Sour Cream", 230, .dairyFats),
        .init("Greek Yogurt", 245, .dairyFats),
        .init("Plain Yogurt", 245, .dairyFats),
        .init("Heavy Cream", 238, .dairyFats),
        .init("Ricotta", 246, .dairyFats),
        .init("Mascarpone", 232, .dairyFats),
        .init("Grated Parmesan", 100, .dairyFats),
        .init("Shredded Cheddar", 113, .dairyFats),

        // Liquids
        .init("Water", 237, .liquids),
        .init("Milk", 244, .liquids),
        .init("Buttermilk", 245, .liquids),
        .init("Half-and-Half", 242, .liquids),
        .init("Vegetable Oil", 218, .liquids),
        .init("Olive Oil", 216, .liquids),
        .init("Coconut Oil", 218, .liquids),
        .init("Melted Butter", 227, .liquids),
        .init("Coffee", 237, .liquids),
        .init("Vinegar", 239, .liquids),
        .init("Soy Sauce", 255, .liquids),
        .init("Almond Milk", 240, .liquids),
        .init("Coconut Milk", 240, .liquids),
        .init("Orange Juice", 248, .liquids),
        .init("Lemon Juice", 245, .liquids),
        .init("Wine", 237, .liquids),

        // Grains
        .init("Rice (uncooked)", 195, .grains),
        .init("Brown Rice (uncooked)", 190, .grains),
        .init("Rolled Oats", 90, .grains),
        .init("Quick Oats", 95, .grains),
        .init("Steel-Cut Oats", 175, .grains),
        .init("Quinoa (uncooked)", 170, .grains),
        .init("Couscous", 173, .grains),
        .init("Barley (uncooked)", 200, .grains),
        .init("Bulgur", 140, .grains),
        .init("Lentils (dry)", 192, .grains),
        .init("Dried Beans", 200, .grains),
        .init("Pasta (dry, elbow)", 105, .grains),
        .init("Breadcrumbs (dry)", 108, .grains),
        .init("Panko", 50, .grains),

        // Baking
        .init("Cocoa Powder", 85, .baking),
        .init("Baking Powder", 192, .baking),
        .init("Baking Soda", 220, .baking),
        .init("Salt (table)", 273, .baking),
        .init("Kosher Salt", 230, .baking),
        .init("Active Dry Yeast", 192, .baking),
        .init("Chocolate Chips", 170, .baking),
        .init("Shredded Coconut", 80, .baking),
        .init("Mini Marshmallows", 50, .baking),
        .init("Cream of Tartar", 160, .baking),
        .init("Matcha Powder", 100, .baking),
        .init("Cornflour", 128, .baking),

        // Nuts & Seeds
        .init("Almonds (whole)", 143, .nutsSeeds),
        .init("Sliced Almonds", 92, .nutsSeeds),
        .init("Walnuts (halves)", 100, .nutsSeeds),
        .init("Pecans (halves)", 99, .nutsSeeds),
        .init("Peanuts", 146, .nutsSeeds),
        .init("Peanut Butter", 258, .nutsSeeds),
        .init("Cashews", 137, .nutsSeeds),
        .init("Pistachios", 123, .nutsSeeds),
        .init("Sunflower Seeds", 140, .nutsSeeds),
        .init("Chia Seeds", 163, .nutsSeeds),
        .init("Flaxseed (whole)", 168, .nutsSeeds),
        .init("Sesame Seeds", 144, .nutsSeeds),
        .init("Pumpkin Seeds", 129, .nutsSeeds),

        // Other
        .init("Raisins", 145, .other),
        .init("Dried Cranberries", 120, .other),
        .init("Honey (warmed)", 340, .other),
        .init("Mashed Banana", 225, .other),
        .init("Pumpkin Purée", 244, .other),
        .init("Applesauce", 244, .other),
        .init("Tomato Paste", 262, .other),
        .init("Mayonnaise", 220, .other),
        .init("Jam", 320, .other)
    ]

    /// Lookup by stable id.
    static func ingredient(id: String) -> IngredientDensity? {
        all.first { $0.id == id }
    }

    static func grouped() -> [(category: IngredientDensity.Category, items: [IngredientDensity])] {
        IngredientDensity.Category.allCases.compactMap { cat in
            let items = all.filter { $0.category == cat }.sorted { $0.name < $1.name }
            return items.isEmpty ? nil : (cat, items)
        }
    }
}

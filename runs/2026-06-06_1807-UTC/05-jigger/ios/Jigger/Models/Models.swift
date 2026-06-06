import Foundation
import SwiftData

enum IngredientCategory: String, Codable, CaseIterable, Identifiable {
    case spirit = "Spirit", liqueur = "Liqueur", wine = "Wine & Vermouth", bitters = "Bitters"
    case mixer = "Mixer", juice = "Juice", syrup = "Syrup", garnish = "Garnish", other = "Other"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .spirit: return "flame"; case .liqueur: return "drop.halffull"; case .wine: return "wineglass"
        case .bitters: return "eyedropper"; case .mixer: return "bubbles.and.sparkles"; case .juice: return "leaf"
        case .syrup: return "drop"; case .garnish: return "carrot"; case .other: return "shippingbox"
        }
    }
    var sortIndex: Int { IngredientCategory.allCases.firstIndex(of: self) ?? 0 }
}

enum Measure: String, Codable, CaseIterable, Identifiable {
    case oz = "oz", ml = "ml", dash = "dash", tsp = "tsp", barspoon = "barspoon"
    case part = "part", piece = "piece", splash = "splash", topUp = "top up"
    var id: String { rawValue }
    /// Whether this measure scales numerically with servings.
    var scalable: Bool { ![.topUp].contains(self) }
}

enum Method: String, Codable, CaseIterable, Identifiable {
    case shaken = "Shaken", stirred = "Stirred", built = "Built", blended = "Blended", thrown = "Thrown"
    var id: String { rawValue }
}

/// An item on the user's shelf.
@Model
final class Ingredient {
    var name: String
    var categoryRaw: String
    var inStock: Bool
    var notes: String

    @Relationship(deleteRule: .nullify, inverse: \RecipeComponent.ingredient)
    var components: [RecipeComponent]

    init(name: String, category: IngredientCategory = .spirit, inStock: Bool = true, notes: String = "") {
        self.name = name; self.categoryRaw = category.rawValue; self.inStock = inStock
        self.notes = notes; self.components = []
    }
    var category: IngredientCategory {
        get { IngredientCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }
}

/// One measured line of a recipe.
@Model
final class RecipeComponent {
    var amount: Double
    var measureRaw: String
    var optional: Bool          // garnishes / "to taste" don't block makeability
    var note: String
    var ingredient: Ingredient?
    var recipe: Recipe?

    init(amount: Double = 1, measure: Measure = .oz, optional: Bool = false,
         note: String = "", ingredient: Ingredient? = nil) {
        self.amount = max(0, amount); self.measureRaw = measure.rawValue
        self.optional = optional; self.note = note; self.ingredient = ingredient
    }
    var measure: Measure { Measure(rawValue: measureRaw) ?? .oz }

    /// Formatted amount, scaled by `servings`. Whole/half fractions read nicely.
    func amountString(servings: Double) -> String {
        guard measure.scalable else { return measure.rawValue }
        let v = amount * servings
        let rounded = (v * 100).rounded() / 100
        let intPart = rounded.rounded(.down)
        let frac = rounded - intPart
        let fracStr: String
        switch (frac * 100).rounded() {
        case 25: fracStr = "¼"; case 50: fracStr = "½"; case 75: fracStr = "¾"
        default: return "\(trimmed(rounded)) \(measure.rawValue)"
        }
        let whole = intPart > 0 ? "\(Int(intPart))" : ""
        return "\(whole)\(fracStr) \(measure.rawValue)".trimmingCharacters(in: .whitespaces)
    }
    private func trimmed(_ d: Double) -> String {
        d == d.rounded() ? String(Int(d)) : String(format: "%.2f", d)
    }
}

@Model
final class Recipe {
    var name: String
    var methodRaw: String
    var glass: String
    var instructions: String
    var notes: String
    var favorite: Bool
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \RecipeComponent.recipe)
    var components: [RecipeComponent]

    init(name: String, method: Method = .shaken, glass: String = "Coupe",
         instructions: String = "", notes: String = "", favorite: Bool = false, createdAt: Date = .now) {
        self.name = name; self.methodRaw = method.rawValue; self.glass = glass
        self.instructions = instructions; self.notes = notes; self.favorite = favorite
        self.createdAt = createdAt; self.components = []
    }
    var method: Method { get { Method(rawValue: methodRaw) ?? .shaken } set { methodRaw = newValue.rawValue } }
}

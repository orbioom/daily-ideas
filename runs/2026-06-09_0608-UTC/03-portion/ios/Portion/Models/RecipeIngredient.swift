import Foundation
import SwiftData

/// The unit a user chose when adding an ingredient. The canonical amount in a
/// `RecipeIngredient` is always grams; the display quantity + unit are kept so
/// the editor can show the friendly value the user typed.
enum MeasureUnit: String, CaseIterable, Identifiable, Codable {
    case gram
    case ounce
    case piece
    case cup
    case tablespoon

    var id: String { rawValue }

    var label: String {
        switch self {
        case .gram: return "g"
        case .ounce: return "oz"
        case .piece: return "piece"
        case .cup: return "cup"
        case .tablespoon: return "tbsp"
        }
    }

    var longLabel: String {
        switch self {
        case .gram: return "Grams"
        case .ounce: return "Ounces"
        case .piece: return "Pieces"
        case .cup: return "Cups"
        case .tablespoon: return "Tablespoons"
        }
    }

    /// Grams per ounce — a fixed physical constant.
    static let gramsPerOunce: Double = 28.3495
    /// Default grams per tablespoon when a food has no better value.
    static let gramsPerTablespoon: Double = 15.0

    static func from(_ raw: String) -> MeasureUnit {
        MeasureUnit(rawValue: raw) ?? .gram
    }
}

/// One ingredient line in a recipe. Crucially this SNAPSHOTS the food's per-100 g
/// macros at the time it was added, so later editing or deleting the source
/// `FoodItem` never silently changes a saved recipe's nutrition.
@Model
final class RecipeIngredient {
    var foodName: String
    var grams: Double            // canonical amount used by the engine
    var displayQuantity: Double  // the number the user typed
    var unitRaw: String          // MeasureUnit.rawValue
    var kcalPer100: Double
    var proteinPer100: Double
    var carbsPer100: Double
    var fatPer100: Double
    var fiberPer100: Double
    var order: Int
    var recipe: Recipe?

    init(foodName: String,
         grams: Double,
         displayQuantity: Double,
         unit: MeasureUnit,
         kcalPer100: Double,
         proteinPer100: Double,
         carbsPer100: Double,
         fatPer100: Double,
         fiberPer100: Double,
         order: Int = 0) {
        self.foodName = foodName
        self.grams = max(0, grams)
        self.displayQuantity = max(0, displayQuantity)
        self.unitRaw = unit.rawValue
        self.kcalPer100 = max(0, kcalPer100)
        self.proteinPer100 = max(0, proteinPer100)
        self.carbsPer100 = max(0, carbsPer100)
        self.fatPer100 = max(0, fatPer100)
        self.fiberPer100 = max(0, fiberPer100)
        self.order = order
    }

    var unit: MeasureUnit { MeasureUnit.from(unitRaw) }

    /// A short "2 cup" / "120 g" style amount label.
    var amountLabel: String {
        let q = displayQuantity
        let qStr = q == q.rounded() ? String(Int(q)) : String(format: "%.1f", q)
        switch unit {
        case .gram, .ounce:
            return "\(qStr) \(unit.label)"
        case .tablespoon:
            return "\(qStr) tbsp"
        default:
            // piece / cup pluralize naturally enough for a label
            let suffix = q == 1 ? unit.label : unit.label + "s"
            return "\(qStr) \(suffix)"
        }
    }

    /// Convenience initializer from a live FoodItem (snapshots its macros).
    convenience init(from food: FoodItem,
                     grams: Double,
                     displayQuantity: Double,
                     unit: MeasureUnit,
                     order: Int = 0) {
        self.init(foodName: food.name,
                  grams: grams,
                  displayQuantity: displayQuantity,
                  unit: unit,
                  kcalPer100: food.kcalPer100,
                  proteinPer100: food.proteinPer100,
                  carbsPer100: food.carbsPer100,
                  fatPer100: food.fatPer100,
                  fiberPer100: food.fiberPer100,
                  order: order)
    }
}

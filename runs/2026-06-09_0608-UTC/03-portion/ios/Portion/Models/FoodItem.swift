import Foundation
import SwiftData

/// A single food in the on-device catalog. Macros are stored per 100 g — the
/// canonical basis Portion uses for every computation. Optional household
/// measures (`gramsPerPiece`, `gramsPerCup`) let the editor offer piece/cup
/// units; a value of 0 means "not applicable" and the unit falls back to grams.
@Model
final class FoodItem {
    var name: String
    var category: String
    var kcalPer100: Double
    var proteinPer100: Double
    var carbsPer100: Double
    var fatPer100: Double
    var fiberPer100: Double
    var gramsPerPiece: Double      // 0 if N/A
    var gramsPerCup: Double        // 0 if N/A
    var isCustom: Bool
    var createdAt: Date

    init(name: String,
         category: String,
         kcalPer100: Double,
         proteinPer100: Double,
         carbsPer100: Double,
         fatPer100: Double,
         fiberPer100: Double,
         gramsPerPiece: Double = 0,
         gramsPerCup: Double = 0,
         isCustom: Bool = false,
         createdAt: Date = .now) {
        self.name = name
        self.category = category
        self.kcalPer100 = max(0, kcalPer100)
        self.proteinPer100 = max(0, proteinPer100)
        self.carbsPer100 = max(0, carbsPer100)
        self.fatPer100 = max(0, fatPer100)
        self.fiberPer100 = max(0, fiberPer100)
        self.gramsPerPiece = max(0, gramsPerPiece)
        self.gramsPerCup = max(0, gramsPerCup)
        self.isCustom = isCustom
        self.createdAt = createdAt
    }
}

/// Catalog categories. `String`-backed so they survive a model change, and
/// ordered for a stable, sensible grouping in the catalog list.
enum FoodCategory: String, CaseIterable, Identifiable {
    case grains = "Grains"
    case protein = "Protein"
    case dairy = "Dairy"
    case vegetable = "Vegetable"
    case fruit = "Fruit"
    case fatOil = "Fat/Oil"
    case legume = "Legume"
    case nutSeed = "Nut/Seed"
    case sweetener = "Sweetener"
    case other = "Other"

    var id: String { rawValue }
    var label: String { rawValue }

    var symbol: String {
        switch self {
        case .grains: return "leaf"
        case .protein: return "fish"
        case .dairy: return "drop"
        case .vegetable: return "carrot"
        case .fruit: return "applelogo"
        case .fatOil: return "drop.triangle"
        case .legume: return "circle.grid.2x2"
        case .nutSeed: return "circle.hexagongrid"
        case .sweetener: return "cube"
        case .other: return "fork.knife"
        }
    }

    /// Stable sort weight used to order catalog sections.
    var sortOrder: Int { FoodCategory.allCases.firstIndex(of: self) ?? 99 }

    static func from(_ raw: String) -> FoodCategory {
        FoodCategory(rawValue: raw) ?? .other
    }
}

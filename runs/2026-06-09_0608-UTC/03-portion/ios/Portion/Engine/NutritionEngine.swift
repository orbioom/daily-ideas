import Foundation

/// A bundle of the five macros Portion tracks. Energy in kcal, the rest in grams.
struct Macros: Equatable {
    var kcal: Double = 0
    var protein: Double = 0
    var carbs: Double = 0
    var fat: Double = 0
    var fiber: Double = 0

    static let zero = Macros()

    static func + (lhs: Macros, rhs: Macros) -> Macros {
        Macros(kcal: lhs.kcal + rhs.kcal,
               protein: lhs.protein + rhs.protein,
               carbs: lhs.carbs + rhs.carbs,
               fat: lhs.fat + rhs.fat,
               fiber: lhs.fiber + rhs.fiber)
    }

    func scaled(by factor: Double) -> Macros {
        let f = factor.isFinite ? factor : 0
        return Macros(kcal: kcal * f,
                      protein: protein * f,
                      carbs: carbs * f,
                      fat: fat * f,
                      fiber: fiber * f)
    }
}

/// A single %Daily-Value row produced for the nutrition label.
struct DailyValueRow: Identifiable {
    let id = UUID()
    let name: String
    let amount: Double      // grams (or kcal for energy)
    let unit: String        // "g" or "kcal"
    let percent: Double     // 0…(may exceed 1)
}

/// The pure computation core. No SwiftUI, no SwiftData side effects — every
/// function is deterministic so the nutrition label is trivially testable.
enum NutritionEngine {

    // MARK: - Reference daily values (FDA 2,000 kcal basis)
    static let refProtein: Double = 50
    static let refCarbs: Double = 275
    static let refFat: Double = 78
    static let refFiber: Double = 28
    static let refCalories: Double = 2000

    // MARK: - Per-ingredient & recipe totals

    /// Macros contributed by one ingredient = per-100 g values × grams / 100.
    static func macros(for ingredient: RecipeIngredient) -> Macros {
        let factor = ingredient.grams / 100.0
        return Macros(kcal: ingredient.kcalPer100,
                      protein: ingredient.proteinPer100,
                      carbs: ingredient.carbsPer100,
                      fat: ingredient.fatPer100,
                      fiber: ingredient.fiberPer100).scaled(by: factor)
    }

    /// Whole-recipe macros = sum over all ingredients.
    static func total(for recipe: Recipe) -> Macros {
        recipe.orderedIngredients.reduce(Macros.zero) { $0 + macros(for: $1) }
    }

    /// Per-serving macros = total ÷ servings (never divides by zero).
    static func perServing(_ recipe: Recipe) -> Macros {
        total(for: recipe).scaled(by: 1.0 / Double(max(1, recipe.safeServings)))
    }

    /// Per-serving macros for an arbitrary serving count — used by the live
    /// serving scaler without mutating the stored recipe.
    static func perServing(_ recipe: Recipe, servings: Int) -> Macros {
        total(for: recipe).scaled(by: 1.0 / Double(max(1, servings)))
    }

    // MARK: - Calorie split (4 / 4 / 9 kcal per gram)

    /// Fraction of calories from protein, carbs, fat. Guards an all-zero recipe.
    static func calorieSplit(_ m: Macros) -> (protein: Double, carbs: Double, fat: Double) {
        let pCal = m.protein * 4
        let cCal = m.carbs * 4
        let fCal = m.fat * 9
        let sum = pCal + cCal + fCal
        guard sum > 0 else { return (0, 0, 0) }
        return (pCal / sum, cCal / sum, fCal / sum)
    }

    // MARK: - %Daily Value

    /// Daily-value rows for a serving of macros, scaled to the user's calorie
    /// target. Macro references scale proportionally to target / 2000 so a
    /// 2,500-kcal target loosens the protein/carb/fat/fiber goals sensibly.
    static func dailyValuePercents(_ m: Macros, calorieTarget: Double) -> [DailyValueRow] {
        let target = max(1, calorieTarget)
        let scale = target / refCalories
        func pct(_ amount: Double, _ ref: Double) -> Double {
            guard ref > 0 else { return 0 }
            return amount / ref
        }
        return [
            DailyValueRow(name: "Calories", amount: m.kcal, unit: "kcal",
                          percent: pct(m.kcal, target)),
            DailyValueRow(name: "Protein", amount: m.protein, unit: "g",
                          percent: pct(m.protein, refProtein * scale)),
            DailyValueRow(name: "Carbohydrate", amount: m.carbs, unit: "g",
                          percent: pct(m.carbs, refCarbs * scale)),
            DailyValueRow(name: "Fat", amount: m.fat, unit: "g",
                          percent: pct(m.fat, refFat * scale)),
            DailyValueRow(name: "Fiber", amount: m.fiber, unit: "g",
                          percent: pct(m.fiber, refFiber * scale))
        ]
    }

    // MARK: - Unit → grams conversion

    /// Convert a user-entered quantity + unit into canonical grams, using the
    /// food's household measures when the unit needs them. Falls back to grams
    /// (treating the quantity as grams) when a measure is unavailable.
    static func grams(for quantity: Double, unit: MeasureUnit, food: FoodItem?) -> Double {
        let q = max(0, quantity)
        switch unit {
        case .gram:
            return q
        case .ounce:
            return q * MeasureUnit.gramsPerOunce
        case .tablespoon:
            return q * MeasureUnit.gramsPerTablespoon
        case .piece:
            let perPiece = food?.gramsPerPiece ?? 0
            return perPiece > 0 ? q * perPiece : q
        case .cup:
            let perCup = food?.gramsPerCup ?? 0
            return perCup > 0 ? q * perCup : q
        }
    }

    /// Which units make sense for a given food (hides piece/cup when the food
    /// has no household measure for them).
    static func availableUnits(for food: FoodItem?) -> [MeasureUnit] {
        var units: [MeasureUnit] = [.gram, .ounce, .tablespoon]
        if let f = food {
            if f.gramsPerPiece > 0 { units.append(.piece) }
            if f.gramsPerCup > 0 { units.append(.cup) }
        }
        return units
    }

    // MARK: - Display rounding

    /// Round calories to whole numbers.
    static func roundedKcal(_ v: Double) -> Int { Int(v.rounded()) }

    /// Round grams to one decimal, dropping a trailing ".0".
    static func gramsString(_ v: Double) -> String {
        let r = (v * 10).rounded() / 10
        return r == r.rounded() ? String(Int(r)) : String(format: "%.1f", r)
    }
}

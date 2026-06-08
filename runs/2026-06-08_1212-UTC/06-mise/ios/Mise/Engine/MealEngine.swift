import Foundation

/// The heart of Mise: scaling recipes by servings and — the thing Paprika users
/// keep asking for — turning a meal plan into a consolidated grocery list where
/// the same ingredient across recipes is summed into one line.
struct MealEngine {
    let calendar: Calendar
    init(calendar: Calendar = .current) { self.calendar = calendar }

    // MARK: - Scaling

    /// Scale factor for cooking `targetServings` of a recipe with `baseServings`.
    func factor(base baseServings: Int, target targetServings: Int) -> Double {
        guard baseServings > 0 else { return 1 }
        return Double(targetServings) / Double(baseServings)
    }

    func scaled(_ ingredient: Ingredient, factor: Double) -> Double {
        ingredient.quantity * factor
    }

    // MARK: - Meal plan grouping

    func plans(_ plans: [MealPlan], on day: Date) -> [MealPlan] {
        plans.filter { calendar.isDate($0.date, inSameDayAs: day) }
            .sorted { $0.mealType.sortIndex < $1.mealType.sortIndex }
    }

    func days(from start: Date, count: Int) -> [Date] {
        let s = calendar.startOfDay(for: start)
        return (0..<count).compactMap { calendar.date(byAdding: .day, value: $0, to: s) }
    }

    // MARK: - Grocery aggregation

    struct AggregatedItem: Identifiable {
        let id = UUID()
        let name: String
        let quantity: Double
        let unit: Unit
        let aisle: Aisle
    }

    /// Consolidate all ingredients from the given meal plans (scaled by each
    /// plan's servings) into one line per (name, unit). Names are matched
    /// case-insensitively and trimmed; quantities sum. Count-less ingredients
    /// (quantity 0) collapse to a single line.
    func groceryList(from mealPlans: [MealPlan]) -> [AggregatedItem] {
        // key: lowercased name + "|" + unit raw
        var map: [String: (name: String, qty: Double, unit: Unit, aisle: Aisle)] = [:]
        for plan in mealPlans {
            guard let recipe = plan.recipe else { continue }
            let f = factor(base: recipe.servings, target: plan.servings)
            for ing in recipe.ingredients {
                let cleanName = ing.name.trimmingCharacters(in: .whitespaces)
                guard !cleanName.isEmpty else { continue }
                let key = cleanName.lowercased() + "|" + ing.unitRaw
                let addQty = ing.quantity * f
                if var existing = map[key] {
                    existing.qty += addQty
                    map[key] = existing
                } else {
                    map[key] = (cleanName, addQty, ing.unit, ing.aisle)
                }
            }
        }
        return map.values
            .map { AggregatedItem(name: $0.name, quantity: $0.qty, unit: $0.unit, aisle: $0.aisle) }
            .sorted { lhs, rhs in
                if lhs.aisle.sortIndex != rhs.aisle.sortIndex { return lhs.aisle.sortIndex < rhs.aisle.sortIndex }
                return lhs.name < rhs.name
            }
    }

    // MARK: - Stats

    func plannedRecipeCount(_ plans: [MealPlan]) -> Int {
        plans.filter { $0.recipe != nil }.count
    }
}

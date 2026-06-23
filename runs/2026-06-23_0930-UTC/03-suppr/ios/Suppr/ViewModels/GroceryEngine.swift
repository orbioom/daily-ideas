import Foundation

/// Aggregated grocery line produced from the meal plan before it becomes a
/// persisted `GroceryItem`.
struct AggregatedLine: Identifiable, Hashable {
    var id: String { sourceKey }
    let name: String
    let unit: String
    let aisle: Aisle
    let quantity: Double
    let isStaple: Bool
    let sourceKey: String
}

/// Pure aggregation logic: turns planned meals into a merged, aisle-grouped
/// shopping list. Kept free of SwiftData / UI so it is trivially testable.
enum GroceryEngine {

    /// Aggregate ingredients across planned meals, scaling by each meal's
    /// chosen servings and merging identical name+unit pairs.
    static func aggregate(from meals: [PlannedMeal]) -> [AggregatedLine] {
        var bucket: [String: AggregatedLine] = [:]

        for meal in meals {
            guard let recipe = meal.recipe else { continue }
            let factor = meal.scaleFactor
            for ing in recipe.ingredients {
                let key = ing.mergeKey
                let scaledQty = ing.quantity * factor
                if let existing = bucket[key] {
                    bucket[key] = AggregatedLine(
                        name: existing.name,
                        unit: existing.unit,
                        aisle: existing.aisle,
                        quantity: existing.quantity + scaledQty,
                        isStaple: existing.isStaple && ing.isStaple,
                        sourceKey: key
                    )
                } else {
                    bucket[key] = AggregatedLine(
                        name: ing.name,
                        unit: ing.unit,
                        aisle: ing.aisle,
                        quantity: scaledQty,
                        isStaple: ing.isStaple,
                        sourceKey: key
                    )
                }
            }
        }

        return bucket.values.sorted { lhs, rhs in
            if lhs.aisle.order != rhs.aisle.order { return lhs.aisle.order < rhs.aisle.order }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }

    /// Group grocery items by aisle in store-walk order, dropping empty aisles.
    static func grouped(_ items: [GroceryItem]) -> [(aisle: Aisle, items: [GroceryItem])] {
        let byAisle = Dictionary(grouping: items, by: { $0.aisle })
        return Aisle.allCases
            .sorted { $0.order < $1.order }
            .compactMap { aisle in
                guard let list = byAisle[aisle], !list.isEmpty else { return nil }
                let sorted = list.sorted {
                    $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                }
                return (aisle, sorted)
            }
    }
}

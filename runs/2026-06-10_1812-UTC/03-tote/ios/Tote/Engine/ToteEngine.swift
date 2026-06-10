import Foundation
import SwiftData

/// Shared grocery logic: catalog memory, aisle resolution, and the
/// recipe → list aggregation that merges duplicate ingredients.
enum ToteEngine {
    static let units = ["", "lb", "oz", "kg", "g", "ct", "dozen", "pack", "bag",
                        "box", "can", "bottle", "jar", "L", "ml", "gal", "qt", "bunch", "loaf"]

    /// Resolve the best aisle for an item name: learned catalog first, else guess.
    static func resolveAisle(for name: String, catalog: [CatalogItem]) -> Aisle {
        let key = name.lowercased().trimmingCharacters(in: .whitespaces)
        if let learned = catalog.first(where: { $0.nameKey == key }) {
            return learned.aisle
        }
        return AisleGuesser.guess(name)
    }

    /// Record that an item was used, updating or creating its catalog entry.
    static func remember(name: String, aisle: Aisle, in context: ModelContext, catalog: [CatalogItem]) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 1 else { return }
        let key = trimmed.lowercased()
        if let existing = catalog.first(where: { $0.nameKey == key }) {
            existing.useCount += 1
            existing.lastUsed = .now
            existing.aisleRaw = aisle.rawValue
        } else {
            let item = CatalogItem(displayName: trimmed, aisle: aisle)
            context.insert(item)
        }
    }

    /// Add a single item to a list, merging with an existing unchecked line that
    /// shares the same name and unit (quantities add up).
    @discardableResult
    static func addItem(name: String, quantity: Double, unit: String, aisle: Aisle,
                        to list: GroceryList, in context: ModelContext) -> ListItem {
        let key = name.lowercased().trimmingCharacters(in: .whitespaces)
        if let match = list.items.first(where: {
            !$0.isChecked && $0.name.lowercased() == key && $0.unit == unit
        }) {
            match.quantity += quantity
            return match
        }
        let nextIndex = (list.items.map { $0.sortIndex }.max() ?? 0) + 1
        let item = ListItem(name: name.trimmingCharacters(in: .whitespaces),
                            quantity: quantity, unit: unit, aisle: aisle, sortIndex: nextIndex)
        item.list = list
        context.insert(item)
        return item
    }

    /// Pour all of a recipe's ingredients into a list, aggregating duplicates.
    /// Returns how many distinct lines were affected.
    @discardableResult
    static func addRecipe(_ recipe: Recipe, to list: GroceryList, in context: ModelContext) -> Int {
        var affected = 0
        for ing in recipe.ingredients {
            _ = addItem(name: ing.name, quantity: ing.quantity, unit: ing.unit,
                        aisle: ing.aisle, to: list, in: context)
            affected += 1
        }
        return affected
    }

    /// Items grouped by aisle in walk order, each group sorted by name.
    static func grouped(_ items: [ListItem]) -> [(aisle: Aisle, items: [ListItem])] {
        Dictionary(grouping: items, by: { $0.aisle })
            .map { (aisle: $0.key, items: $0.value.sorted { $0.name < $1.name }) }
            .sorted { $0.aisle.order < $1.aisle.order }
    }
}

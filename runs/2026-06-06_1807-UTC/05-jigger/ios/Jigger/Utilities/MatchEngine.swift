import Foundation

/// The heart of Jigger: given the user's shelf (each Ingredient's `inStock`),
/// decide which recipes are makeable, which are one ingredient away, and which
/// single purchase would unlock the most recipes.
enum MatchEngine {

    struct Result {
        var makeable: Bool
        var missing: [Ingredient]       // required, out-of-stock or unknown ingredients
        var requiredCount: Int
        var missingCount: Int { missing.count }
    }

    /// Evaluate one recipe against current stock.
    static func evaluate(_ recipe: Recipe) -> Result {
        let required = recipe.components.filter { !$0.optional }
        var missing: [Ingredient] = []
        for c in required {
            if let ing = c.ingredient {
                if !ing.inStock { missing.append(ing) }
            }
            // A component with no linked ingredient can't be satisfied; treat as
            // blocking but not surfaced as a buyable item (it has no Ingredient).
        }
        let unknownBlocking = required.contains { $0.ingredient == nil }
        return Result(makeable: missing.isEmpty && !unknownBlocking,
                      missing: dedup(missing),
                      requiredCount: required.count)
    }

    private static func dedup(_ items: [Ingredient]) -> [Ingredient] {
        var seen = Set<PersistentIdentifier>()
        return items.filter { seen.insert($0.persistentModelID).inserted }
    }

    /// Recipes you can make right now, sorted by favorite then name.
    static func makeable(_ recipes: [Recipe]) -> [Recipe] {
        recipes.filter { evaluate($0).makeable }
            .sorted { ($0.favorite ? 0 : 1, $0.name) < ($1.favorite ? 0 : 1, $1.name) }
    }

    /// Recipes missing exactly one required ingredient, with that ingredient.
    static func oneAway(_ recipes: [Recipe]) -> [(recipe: Recipe, missing: Ingredient)] {
        recipes.compactMap { r in
            let res = evaluate(r)
            guard !res.makeable, res.missingCount == 1, let m = res.missing.first else { return nil }
            return (recipe: r, missing: m)
        }
        .sorted { $0.recipe.name < $1.recipe.name }
    }

    /// Ranked shopping suggestions: each out-of-stock ingredient that is the sole
    /// blocker for one or more recipes, ordered by how many it would unlock.
    static func shoppingSuggestions(_ recipes: [Recipe]) -> [(ingredient: Ingredient, unlocks: [Recipe])] {
        var map: [PersistentIdentifier: (Ingredient, [Recipe])] = [:]
        for r in recipes {
            let res = evaluate(r)
            guard !res.makeable, res.missingCount == 1, let m = res.missing.first else { continue }
            var entry = map[m.persistentModelID] ?? (m, [])
            entry.1.append(r)
            map[m.persistentModelID] = entry
        }
        return map.values
            .map { (ingredient: $0.0, unlocks: $0.1) }
            .sorted { a, b in
                if a.unlocks.count != b.unlocks.count { return a.unlocks.count > b.unlocks.count }
                return a.ingredient.name < b.ingredient.name
            }
    }
}

import Foundation

/// Result of matching one recipe against a pantry.
struct MatchResult {
    let recipe: Recipe
    let requiredCount: Int
    let haveCount: Int
    /// Required ingredients the pantry is missing.
    let missing: [RecipeIngredient]
    /// Optional ingredients the pantry is missing (informational only).
    let missingOptional: [RecipeIngredient]

    /// All required ingredients present (staples counted when assumed).
    var isMakeable: Bool { missing.isEmpty }
    /// Exactly one required ingredient missing.
    var oneAway: Bool { missing.count == 1 }
    /// have / required, guarded against divide-by-zero. Range 0...1.
    var matchPercent: Double {
        guard requiredCount > 0 else { return 1 }
        return min(1, max(0, Double(haveCount) / Double(requiredCount)))
    }
    /// Whole-number percent for display.
    var matchPercentInt: Int { Int((matchPercent * 100).rounded()) }
}

/// Pure pantry → recipe matching. No SwiftData, no UI; fully testable.
enum MatchEngine {

    /// Ingredients assumed to be on hand when "assume staples" is on.
    static let staples: Set<String> = {
        let raw = ["salt", "pepper", "black pepper", "water", "oil", "olive oil",
                   "vegetable oil", "butter", "sugar", "flour", "garlic", "onion"]
        return Set(raw.map { IngredientNormalizer.normalize($0) })
    }()

    /// True if a single ingredient is satisfied by the have-set (or staples).
    /// Public so detail views can highlight per-row have/missing without
    /// allocating probe recipes.
    static func isSatisfied(_ ingredient: RecipeIngredient,
                            have: Set<String>,
                            assumeStaples: Bool) -> Bool {
        let key = ingredient.normalizedName
        if key.isEmpty { return true }
        if have.contains(key) { return true }
        if assumeStaples && staples.contains(key) { return true }
        // Loose containment both directions so "tomato" matches "tomato paste" etc.
        for h in have where !h.isEmpty {
            if h == key || h.contains(key) || key.contains(h) { return true }
        }
        return false
    }

    /// Match a single recipe against the have-set.
    static func matchResult(_ recipe: Recipe,
                            have: Set<String>,
                            assumeStaples: Bool) -> MatchResult {
        let required = recipe.ingredients.filter { !$0.optional }
        let optional = recipe.ingredients.filter { $0.optional }

        var missing: [RecipeIngredient] = []
        var haveCount = 0
        for ing in required {
            if isSatisfied(ing, have: have, assumeStaples: assumeStaples) {
                haveCount += 1
            } else {
                missing.append(ing)
            }
        }

        let missingOptional = optional.filter {
            !isSatisfied($0, have: have, assumeStaples: assumeStaples)
        }

        return MatchResult(recipe: recipe,
                           requiredCount: required.count,
                           haveCount: haveCount,
                           missing: missing,
                           missingOptional: missingOptional)
    }

    /// Rank recipes: makeable first, then one-away, then by match percent desc,
    /// then fewer missing, then name for stability.
    static func rankedRecipes(_ recipes: [Recipe],
                              have: Set<String>,
                              assumeStaples: Bool) -> [MatchResult] {
        recipes
            .map { matchResult($0, have: have, assumeStaples: assumeStaples) }
            .sorted { lhs, rhs in
                if lhs.isMakeable != rhs.isMakeable { return lhs.isMakeable }
                if lhs.oneAway != rhs.oneAway { return lhs.oneAway }
                if lhs.matchPercent != rhs.matchPercent { return lhs.matchPercent > rhs.matchPercent }
                if lhs.missing.count != rhs.missing.count { return lhs.missing.count < rhs.missing.count }
                return lhs.recipe.name.localizedCaseInsensitiveCompare(rhs.recipe.name) == .orderedAscending
            }
    }

    /// One suggested ingredient to buy and the recipes it would newly unlock.
    struct Unlock: Identifiable {
        let name: String          // display name (first seen casing)
        let normalized: String
        let unlockedRecipes: [Recipe]
        var id: String { normalized }
        var count: Int { unlockedRecipes.count }
    }

    /// For each currently-missing required ingredient, how many additional recipes
    /// would become makeable if you bought it. Ranked by impact desc.
    static func shoppingUnlocks(_ recipes: [Recipe],
                                have: Set<String>,
                                assumeStaples: Bool) -> [Unlock] {
        // Candidates: required ingredients missing from recipes that are exactly one away.
        var byKey: [String: (display: String, recipes: [Recipe])] = [:]

        for recipe in recipes {
            let result = matchResult(recipe, have: have, assumeStaples: assumeStaples)
            guard result.oneAway, let only = result.missing.first else { continue }
            let key = only.normalizedName
            guard !key.isEmpty else { continue }
            if var entry = byKey[key] {
                entry.recipes.append(recipe)
                byKey[key] = entry
            } else {
                byKey[key] = (display: only.name, recipes: [recipe])
            }
        }

        return byKey
            .map { Unlock(name: $0.value.display,
                          normalized: $0.key,
                          unlockedRecipes: $0.value.recipes) }
            .sorted { lhs, rhs in
                if lhs.count != rhs.count { return lhs.count > rhs.count }
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
    }
}

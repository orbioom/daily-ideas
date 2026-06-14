import Foundation

/// Pure helpers for turning a pantry list into the normalized "have" set
/// consumed by `MatchEngine`. No SwiftData or UI dependencies.
enum PantryStore {

    /// The normalized names of every in-stock pantry item.
    static func haveSet(from items: [PantryItem]) -> Set<String> {
        var set = Set<String>()
        for item in items where item.inStock {
            let key = item.normalizedName
            if !key.isEmpty { set.insert(key) }
        }
        return set
    }

    /// Convenience: rank recipes directly from pantry items.
    static func rankedRecipes(_ recipes: [Recipe],
                              pantry: [PantryItem],
                              assumeStaples: Bool) -> [MatchResult] {
        MatchEngine.rankedRecipes(recipes,
                                  have: haveSet(from: pantry),
                                  assumeStaples: assumeStaples)
    }
}

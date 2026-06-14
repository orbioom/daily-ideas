import Foundation

/// Free-tier limits and Pro gating logic.
enum Pro {
    /// Free users can create up to this many custom recipes. Browsing is unlimited.
    static let freeCustomRecipeLimit = 5

    /// Display price for the one-time unlock.
    static let priceLabel = "$3.99"

    /// Whether another custom recipe can be added given current count and Pro status.
    static func canAddCustomRecipe(currentCustomCount: Int, isPro: Bool) -> Bool {
        if isPro { return true }
        return currentCustomCount < freeCustomRecipeLimit
    }

    /// Remaining free custom-recipe slots (nil when Pro = unlimited).
    static func remainingFreeSlots(currentCustomCount: Int, isPro: Bool) -> Int? {
        if isPro { return nil }
        return max(freeCustomRecipeLimit - currentCustomCount, 0)
    }
}

/// Reasons the paywall is presented.
enum PaywallReason: Identifiable {
    case recipeLimit
    case export

    var id: String {
        switch self {
        case .recipeLimit: return "recipeLimit"
        case .export: return "export"
        }
    }

    var title: String {
        switch self {
        case .recipeLimit: return "You've filled your recipe box"
        case .export: return "Export your shopping list"
        }
    }

    var blurb: String {
        switch self {
        case .recipeLimit:
            return "Free Skillet saves up to \(Pro.freeCustomRecipeLimit) of your own recipes. Go Pro to add unlimited custom recipes."
        case .export:
            return "Copy or share your whole shopping list as clean text, ready for the store."
        }
    }

    var symbol: String {
        switch self {
        case .recipeLimit: return "infinity"
        case .export: return "square.and.arrow.up"
        }
    }
}

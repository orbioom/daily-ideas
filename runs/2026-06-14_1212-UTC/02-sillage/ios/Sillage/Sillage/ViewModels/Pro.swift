import Foundation

/// Free-tier limits and Pro gating logic.
enum Pro {
    /// Free users can keep up to this many fragrances (owned + decant + wishlist + sold). Pro = unlimited.
    static let freeCollectionLimit = 15

    /// Display price for the one-time unlock.
    static let priceLabel = "$4.99"

    /// Whether a new fragrance can be added given the current total and Pro status.
    static func canAdd(currentCount: Int, isPro: Bool) -> Bool {
        if isPro { return true }
        return currentCount < freeCollectionLimit
    }

    /// Remaining free slots (nil when Pro = unlimited).
    static func remainingFreeSlots(currentCount: Int, isPro: Bool) -> Int? {
        if isPro { return nil }
        return max(freeCollectionLimit - currentCount, 0)
    }
}

/// Reasons the paywall is presented.
enum PaywallReason: Identifiable {
    case collectionLimit
    case stats
    case export

    var id: String {
        switch self {
        case .collectionLimit: return "collectionLimit"
        case .stats: return "stats"
        case .export: return "export"
        }
    }

    var title: String {
        switch self {
        case .collectionLimit: return "Your free shelf is full"
        case .stats: return "Unlock your full Scent Stats"
        case .export: return "Export your collection"
        }
    }

    var blurb: String {
        switch self {
        case .collectionLimit:
            return "Free Sillage holds up to \(Pro.freeCollectionLimit) fragrances. Go Pro for an unlimited collection."
        case .stats:
            return "See your note-family breakdown, season & occasion maps, house spread, wears over time, and cost-per-wear leaderboard."
        case .export:
            return "Copy or share your entire collection and wear log as clean text or CSV."
        }
    }

    var symbol: String {
        switch self {
        case .collectionLimit: return "infinity"
        case .stats: return "chart.pie.fill"
        case .export: return "square.and.arrow.up"
        }
    }
}

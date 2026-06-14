import Foundation

/// Free-tier limits and Pro gating logic.
enum Pro {
    /// Free users can rank up to this many visited restaurants. Wishlist is unlimited.
    static let freeRankedLimit = 15

    /// Display price for the one-time unlock.
    static let priceLabel = "$4.99"

    /// Whether a new ranked place can be added given the current ranked count and Pro status.
    static func canAddRanked(currentRankedCount: Int, isPro: Bool) -> Bool {
        if isPro { return true }
        return currentRankedCount < freeRankedLimit
    }

    /// Remaining free ranked slots (nil when Pro = unlimited).
    static func remainingFreeSlots(currentRankedCount: Int, isPro: Bool) -> Int? {
        if isPro { return nil }
        return max(freeRankedLimit - currentRankedCount, 0)
    }
}

/// Reasons the paywall is presented.
enum PaywallReason: Identifiable {
    case rankLimit
    case stats
    case export

    var id: String {
        switch self {
        case .rankLimit: return "rankLimit"
        case .stats: return "stats"
        case .export: return "export"
        }
    }

    var title: String {
        switch self {
        case .rankLimit: return "You've filled your free shelf"
        case .stats: return "Unlock your full Taste Stats"
        case .export: return "Export your list"
        }
    }

    var blurb: String {
        switch self {
        case .rankLimit:
            return "Free Relish ranks up to \(Pro.freeRankedLimit) places. Go Pro for an unlimited ranked list."
        case .stats:
            return "See your cuisine and city breakdowns, score histogram, and spend totals."
        case .export:
            return "Copy your entire ranked list as clean text to save or share."
        }
    }

    var symbol: String {
        switch self {
        case .rankLimit: return "infinity"
        case .stats: return "chart.bar.fill"
        case .export: return "square.and.arrow.up"
        }
    }
}

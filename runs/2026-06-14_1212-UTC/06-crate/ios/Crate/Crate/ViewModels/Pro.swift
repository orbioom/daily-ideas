import Foundation

/// Free-tier limits and Pro gating logic.
enum Pro {
    /// Free users can keep up to this many records in their collection. Wantlist is unlimited.
    static let freeCollectionLimit = 25

    /// Display price for the one-time unlock.
    static let priceLabel = "$4.99"

    /// Whether a new owned record can be added given the current owned count and Pro status.
    static func canAddOwned(currentOwnedCount: Int, isPro: Bool) -> Bool {
        if isPro { return true }
        return currentOwnedCount < freeCollectionLimit
    }

    /// Remaining free collection slots (nil when Pro = unlimited).
    static func remainingFreeSlots(currentOwnedCount: Int, isPro: Bool) -> Int? {
        if isPro { return nil }
        return max(freeCollectionLimit - currentOwnedCount, 0)
    }
}

/// Reasons the paywall is presented.
enum PaywallReason: Identifiable {
    case collectionLimit
    case stats
    case export
    case values

    var id: String {
        switch self {
        case .collectionLimit: return "collectionLimit"
        case .stats: return "stats"
        case .export: return "export"
        case .values: return "values"
        }
    }

    var title: String {
        switch self {
        case .collectionLimit: return "Your free crate is full"
        case .stats: return "Unlock the full Stats room"
        case .export: return "Export your collection"
        case .values: return "Track what your crate is worth"
        }
    }

    var blurb: String {
        switch self {
        case .collectionLimit:
            return "Free Crate holds up to \(Pro.freeCollectionLimit) records. Go Pro for an unlimited collection."
        case .stats:
            return "See genre, decade, format and condition breakdowns, your spins-over-time, and value-by-genre."
        case .export:
            return "Save or share your whole collection as clean text or CSV."
        case .values:
            return "Pro tracks total collection value, value-by-genre, and price-paid versus estimate."
        }
    }

    var symbol: String {
        switch self {
        case .collectionLimit: return "infinity"
        case .stats: return "chart.bar.fill"
        case .export: return "square.and.arrow.up"
        case .values: return "dollarsign.circle.fill"
        }
    }
}

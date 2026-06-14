import Foundation

/// Cross-collection helpers that aren't part of the heavier StatsEngine pass:
/// neglected bottles, most-worn, and collection value.
enum WardrobeEngine {

    /// Owned/decant bottles not worn within `thresholdDays`, most-stale first.
    /// A bottle never worn counts as neglected (sorted by date added as a proxy).
    static func neglected(fragrances: [Fragrance], thresholdDays: Int, now: Date = .now) -> [NeglectedRow] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -max(thresholdDays, 0), to: now) ?? now
        let candidates = fragrances.filter { $0.status.isInCollection }

        let stale = candidates.filter { f in
            if let last = f.lastWorn { return last < cutoff }
            return true   // never worn
        }

        return stale
            .sorted { lhs, rhs in
                let l = lhs.lastWorn ?? lhs.addedAt
                let r = rhs.lastWorn ?? rhs.addedAt
                return l < r   // oldest first = most neglected
            }
            .map { NeglectedRow(id: $0.id, name: $0.name, house: $0.house, lastWorn: $0.lastWorn, family: $0.primaryFamily) }
    }

    /// Collection sorted by times worn, descending.
    static func mostWorn(fragrances: [Fragrance], limit: Int? = nil) -> [Fragrance] {
        let sorted = fragrances
            .filter { $0.status.isInCollection }
            .sorted { $0.timesWorn > $1.timesWorn }
        if let limit { return Array(sorted.prefix(limit)) }
        return sorted
    }

    /// Total value of owned bottles (price × bottles owned).
    static func collectionValue(fragrances: [Fragrance]) -> Double {
        let v = fragrances
            .filter { $0.status == .owned }
            .reduce(0.0) { $0 + $1.pricePaid * Double(max($1.bottlesOwned, 1)) }
        return (v * 100).rounded() / 100
    }
}

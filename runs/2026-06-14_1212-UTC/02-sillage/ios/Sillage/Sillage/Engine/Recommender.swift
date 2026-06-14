import Foundation

/// "What to wear tonight" recommender.
enum Recommender {

    /// Owned/decant fragrances eligible for the chosen season + occasion,
    /// ranked by least-recently-worn, then higher rating.
    /// A fragrance is eligible if it lists the season AND occasion, OR has no
    /// constraints recorded for that axis (so sparsely-tagged bottles still surface).
    static func recommend(fragrances: [Fragrance],
                          season: Season,
                          occasion: Occasion) -> [Fragrance] {
        let pool = fragrances.filter { $0.status.isInCollection }

        let eligible = pool.filter { f in
            let seasonOK = f.seasons.isEmpty || f.seasons.contains(season)
            let occasionOK = f.occasions.isEmpty || f.occasions.contains(occasion)
            return seasonOK && occasionOK
        }

        return eligible.sorted { lhs, rhs in
            // Least-recently-worn first. Never-worn (nil) sorts before any worn date.
            let l = lhs.lastWorn
            let r = rhs.lastWorn
            switch (l, r) {
            case (nil, nil):
                if lhs.rating != rhs.rating { return lhs.rating > rhs.rating }
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            case (nil, .some):
                return true
            case (.some, nil):
                return false
            case let (.some(ld), .some(rd)):
                if ld != rd { return ld < rd }
                if lhs.rating != rhs.rating { return lhs.rating > rhs.rating }
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
        }
    }

    /// The most recent wears across the collection, newest first.
    static func recentlyWorn(fragrances: [Fragrance], limit: Int = 10) -> [(fragrance: Fragrance, date: Date)] {
        var pairs: [(Fragrance, Date)] = []
        for f in fragrances {
            if let last = f.lastWorn { pairs.append((f, last)) }
        }
        return Array(pairs.sorted { $0.1 > $1.1 }.prefix(limit))
            .map { (fragrance: $0.0, date: $0.1) }
    }
}

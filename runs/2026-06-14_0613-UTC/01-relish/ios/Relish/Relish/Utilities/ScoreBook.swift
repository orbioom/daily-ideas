import Foundation

/// Precomputes the 0–10 score for every visited restaurant once, so views and
/// stats share one consistent mapping derived from the full ordered set.
struct ScoreBook {
    private let scores: [UUID: Double]

    init(allRestaurants: [Restaurant]) {
        let ordered = allRestaurants
            .filter { !$0.isWishlist && $0.sentiment != nil }
            .sorted { $0.rankIndex < $1.rankIndex }
        var map: [UUID: Double] = [:]
        for r in ordered {
            map[r.id] = RankingEngine.score(for: r, in: ordered)
        }
        self.scores = map
    }

    /// Score for a restaurant, or 0 if it isn't a ranked/visited place.
    func score(_ restaurant: Restaurant) -> Double {
        scores[restaurant.id] ?? 0
    }
}

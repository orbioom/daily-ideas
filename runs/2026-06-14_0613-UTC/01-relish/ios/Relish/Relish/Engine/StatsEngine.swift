import Foundation

struct CategoryCount: Identifiable {
    let id = UUID()
    let label: String
    let count: Int
    let cuisine: Cuisine?     // nil for non-cuisine categories (e.g. cities)
}

struct ScoreBin: Identifiable {
    let id = UUID()
    let lower: Int            // inclusive integer band, e.g. 8 → "8–9"
    let count: Int
    var label: String { "\(lower)" }
}

struct TopDish: Identifiable {
    let id = UUID()
    let name: String
    let restaurant: String
    let rating: Int
}

struct StatsResult {
    var totalRanked: Int = 0
    var totalWishlist: Int = 0
    var averageScore: Double = 0
    var totalSpent: Double = 0
    var visitCount: Int = 0
    var cuisineCounts: [CategoryCount] = []
    var cityCounts: [CategoryCount] = []
    var scoreHistogram: [ScoreBin] = []
    var topDishes: [TopDish] = []

    var isEmpty: Bool { totalRanked == 0 && totalWishlist == 0 }
}

enum StatsEngine {

    /// Pure computation. `scoreFor` supplies the engine-derived 0...10 score per restaurant.
    static func compute(restaurants: [Restaurant],
                        scoreFor: (Restaurant) -> Double) -> StatsResult {
        var result = StatsResult()

        let ranked = restaurants.filter { !$0.isWishlist }
        let wishlist = restaurants.filter { $0.isWishlist }
        result.totalRanked = ranked.count
        result.totalWishlist = wishlist.count

        // Average score
        if !ranked.isEmpty {
            let sum = ranked.reduce(0.0) { $0 + scoreFor($1) }
            result.averageScore = (sum / Double(ranked.count) * 10).rounded() / 10
        }

        // Cuisine distribution (ranked + wishlist together for a fuller picture)
        var cuisineMap: [Cuisine: Int] = [:]
        for r in restaurants { cuisineMap[r.cuisine, default: 0] += 1 }
        result.cuisineCounts = cuisineMap
            .map { CategoryCount(label: $0.key.rawValue, count: $0.value, cuisine: $0.key) }
            .sorted { $0.count > $1.count }

        // City distribution
        var cityMap: [String: Int] = [:]
        for r in restaurants {
            let key = r.city.trimmingCharacters(in: .whitespaces)
            guard !key.isEmpty else { continue }
            cityMap[key, default: 0] += 1
        }
        result.cityCounts = cityMap
            .map { CategoryCount(label: $0.key, count: $0.value, cuisine: nil) }
            .sorted { $0.count > $1.count }

        // Score histogram in 0..10 integer bins (only ranked)
        var bins = Array(repeating: 0, count: 11)
        for r in ranked {
            let s = scoreFor(r)
            let idx = min(max(Int(s.rounded(.down)), 0), 10)
            bins[idx] += 1
        }
        result.scoreHistogram = bins.enumerated().map { ScoreBin(lower: $0.offset, count: $0.element) }

        // Spend totals & visit count
        var spend = 0.0
        var visits = 0
        for r in restaurants {
            for v in r.visits {
                visits += 1
                if let amt = v.amountSpent { spend += amt }
            }
        }
        result.totalSpent = (spend * 100).rounded() / 100
        result.visitCount = visits

        // Top dishes (rating 5 first), cap 10
        var dishes: [TopDish] = []
        for r in restaurants {
            for d in r.dishes {
                dishes.append(TopDish(name: d.name, restaurant: r.name, rating: d.rating))
            }
        }
        result.topDishes = Array(dishes.sorted { $0.rating > $1.rating }.prefix(10))

        return result
    }
}

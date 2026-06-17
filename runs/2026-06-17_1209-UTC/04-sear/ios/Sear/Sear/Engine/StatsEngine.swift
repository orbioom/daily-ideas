import Foundation

/// A labelled count for charts.
struct CountItem: Identifiable {
    let id = UUID()
    let label: String
    let count: Int
    let hue: ColorToken
}

/// A rating point over time.
struct RatingPoint: Identifiable {
    let id = UUID()
    let date: Date
    let rating: Double
    let name: String
}

/// Color reference resolved by the view (keeps the engine UI-free).
enum ColorToken {
    case protein(Protein)
    case method(CookMethod)
    case accent
    case ember
}

/// Aggregated cook statistics.
struct StatsResult {
    var totalCooks: Int = 0
    var doneCooks: Int = 0
    var averageRating: Double = 0
    var byProtein: [CountItem] = []
    var byMethod: [CountItem] = []
    var favoriteWoods: [CountItem] = []
    var favoriteRubs: [CountItem] = []
    var ratingsOverTime: [RatingPoint] = []

    var isEmpty: Bool { totalCooks == 0 }
}

/// Pure aggregation over the cook log. No traps; all divisions guarded.
enum StatsEngine {

    static func compute(cooks: [Cook]) -> StatsResult {
        var r = StatsResult()
        r.totalCooks = cooks.count
        guard !cooks.isEmpty else { return r }

        let done = cooks.filter { $0.status == .done }
        r.doneCooks = done.count

        // Average rating across rated cooks.
        let rated = done.compactMap { $0.clampedRating }
        if !rated.isEmpty {
            r.averageRating = Double(rated.reduce(0, +)) / Double(rated.count)
        }

        // By protein.
        var proteinCounts: [Protein: Int] = [:]
        for c in cooks { proteinCounts[c.protein, default: 0] += 1 }
        r.byProtein = proteinCounts
            .map { CountItem(label: $0.key.label, count: $0.value, hue: .protein($0.key)) }
            .sorted { $0.count > $1.count }

        // By method.
        var methodCounts: [CookMethod: Int] = [:]
        for c in cooks { methodCounts[c.method, default: 0] += 1 }
        r.byMethod = methodCounts
            .map { CountItem(label: $0.key.label, count: $0.value, hue: .method($0.key)) }
            .sorted { $0.count > $1.count }

        // Favorite woods.
        var woodCounts: [String: Int] = [:]
        for c in cooks {
            if let w = c.woodType, !w.isEmpty { woodCounts[w, default: 0] += 1 }
        }
        r.favoriteWoods = woodCounts
            .map { CountItem(label: $0.key, count: $0.value, hue: .ember) }
            .sorted { $0.count > $1.count }

        // Favorite rubs.
        var rubCounts: [String: Int] = [:]
        for c in cooks {
            if let rub = c.rubName, !rub.isEmpty { rubCounts[rub, default: 0] += 1 }
        }
        r.favoriteRubs = rubCounts
            .map { CountItem(label: $0.key, count: $0.value, hue: .accent) }
            .sorted { $0.count > $1.count }

        // Ratings over time (rated, done cooks with a finish date).
        r.ratingsOverTime = done
            .compactMap { cook -> RatingPoint? in
                guard let rating = cook.clampedRating else { return nil }
                let date = cook.finishedDate ?? cook.createdAt
                return RatingPoint(date: date, rating: Double(rating), name: cook.name)
            }
            .sorted { $0.date < $1.date }

        return r
    }
}

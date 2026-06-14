import Foundation

// MARK: Result value types

struct FamilySlice: Identifiable {
    let id = UUID()
    let family: NoteFamily
    let count: Int
}

struct SeasonCount: Identifiable {
    let id = UUID()
    let season: Season
    let count: Int
}

struct OccasionCount: Identifiable {
    let id = UUID()
    let occasion: Occasion
    let count: Int
}

struct HouseCount: Identifiable {
    let id = UUID()
    let house: String
    let count: Int
}

struct WearPoint: Identifiable {
    let id = UUID()
    let monthStart: Date
    let label: String
    let count: Int
}

struct CostPerWearRow: Identifiable {
    let id: UUID
    let name: String
    let house: String
    let costPerWear: Double
    let timesWorn: Int
    let family: NoteFamily
}

struct NeglectedRow: Identifiable {
    let id: UUID
    let name: String
    let house: String
    let lastWorn: Date?
    let family: NoteFamily
}

struct StatsResult {
    var collectionCount: Int = 0      // owned + decant
    var totalValue: Double = 0        // owned only
    var wearsThisMonth: Int = 0
    var totalWears: Int = 0
    var familySlices: [FamilySlice] = []
    var seasonCounts: [SeasonCount] = []
    var occasionCounts: [OccasionCount] = []
    var houseCounts: [HouseCount] = []
    var wearsOverTime: [WearPoint] = []
    var costPerWear: [CostPerWearRow] = []

    var isEmpty: Bool { collectionCount == 0 && totalWears == 0 }
}

/// Pure, testable wardrobe statistics computed off a snapshot of fragrances.
enum StatsEngine {

    static func compute(fragrances: [Fragrance], now: Date = .now) -> StatsResult {
        var r = StatsResult()

        let collection = fragrances.filter { $0.status.isInCollection }
        let owned = fragrances.filter { $0.status == .owned }
        r.collectionCount = collection.count
        r.totalValue = (owned.reduce(0.0) { $0 + $1.pricePaid } * 100).rounded() / 100

        // Wears
        let allWears = fragrances.flatMap { $0.wears }
        r.totalWears = allWears.count

        let cal = Calendar.current
        let monthStartNow = cal.dateInterval(of: .month, for: now)?.start ?? now
        r.wearsThisMonth = allWears.filter { $0.date >= monthStartNow }.count

        // Note-family distribution across the collection (count each fragrance once per family present).
        var familyMap: [NoteFamily: Int] = [:]
        for f in collection {
            for fam in f.families { familyMap[fam, default: 0] += 1 }
        }
        r.familySlices = familyMap
            .map { FamilySlice(family: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }

        // Season suitability across the collection.
        var seasonMap: [Season: Int] = [:]
        for f in collection {
            for s in f.seasons { seasonMap[s, default: 0] += 1 }
        }
        r.seasonCounts = Season.allCases.map { SeasonCount(season: $0, count: seasonMap[$0] ?? 0) }

        // Occasion suitability across the collection.
        var occasionMap: [Occasion: Int] = [:]
        for f in collection {
            for o in f.occasions { occasionMap[o, default: 0] += 1 }
        }
        r.occasionCounts = Occasion.allCases.map { OccasionCount(occasion: $0, count: occasionMap[$0] ?? 0) }

        // House breakdown.
        var houseMap: [String: Int] = [:]
        for f in collection {
            let key = f.house.trimmingCharacters(in: .whitespaces)
            guard !key.isEmpty else { continue }
            houseMap[key, default: 0] += 1
        }
        r.houseCounts = houseMap
            .map { HouseCount(house: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }

        // Wears over the last 6 months.
        r.wearsOverTime = monthlyWearSeries(wears: allWears, now: now, months: 6)

        // Cost-per-wear leaderboard (owned + decant with a price).
        r.costPerWear = collection
            .filter { $0.pricePaid > 0 }
            .map {
                CostPerWearRow(id: $0.id,
                               name: $0.name,
                               house: $0.house,
                               costPerWear: $0.costPerWear,
                               timesWorn: $0.timesWorn,
                               family: $0.primaryFamily)
            }
            .sorted { $0.costPerWear < $1.costPerWear }

        return r
    }

    /// Monthly wear counts for the last `months` calendar months ending at `now`.
    static func monthlyWearSeries(wears: [WearLog], now: Date, months: Int) -> [WearPoint] {
        let cal = Calendar.current
        guard months > 0,
              let thisMonthStart = cal.dateInterval(of: .month, for: now)?.start else { return [] }

        var buckets: [Date] = []
        for back in stride(from: months - 1, through: 0, by: -1) {
            if let d = cal.date(byAdding: .month, value: -back, to: thisMonthStart) {
                buckets.append(d)
            }
        }

        let fmt = DateFormatter()
        fmt.dateFormat = "MMM"

        return buckets.map { start in
            let end = cal.date(byAdding: .month, value: 1, to: start) ?? start
            let count = wears.filter { $0.date >= start && $0.date < end }.count
            return WearPoint(monthStart: start, label: fmt.string(from: start), count: count)
        }
    }
}

import Foundation

/// A labelled count for a category (genre / format / condition / decade).
struct CategoryCount: Identifiable {
    let id = UUID()
    let label: String
    let count: Int
    /// Genre when this row represents a genre, else nil.
    let genre: Genre?
}

/// A labelled monetary total for a category.
struct CategoryValue: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
    let genre: Genre?
}

/// A point in the spins-over-time series (one per recent month).
struct MonthPoint: Identifiable {
    let id = UUID()
    /// First day of the month.
    let month: Date
    let count: Int
    /// "Mar" style short label.
    var label: String { month.formatted(.dateTime.month(.abbreviated)) }
}

/// A record paired with a derived metric for "most spun" lists.
struct SpinRanked: Identifiable {
    let id: UUID
    let title: String
    let artist: String
    let coverHue: Double
    let spins: Int
}

/// The full computed stats payload.
struct StatsResult {
    var ownedCount: Int = 0
    var wantlistCount: Int = 0
    var collectionValue: Double = 0
    var totalPaid: Double = 0
    var totalSpins: Int = 0
    var spinsThisMonth: Int = 0
    var neverSpunCount: Int = 0
    var averageTrackCount: Double = 0

    var byGenre: [CategoryCount] = []
    var byDecade: [CategoryCount] = []
    var byFormat: [CategoryCount] = []
    var byCondition: [CategoryCount] = []
    var valueByGenre: [CategoryValue] = []
    var spinsOverTime: [MonthPoint] = []
    var mostSpun: [SpinRanked] = []

    var isEmpty: Bool { ownedCount == 0 && wantlistCount == 0 }
}

/// Pure, guarded computation over the collection. Owned-only where value is implied.
enum StatsEngine {

    static func compute(records: [Record], now: Date = .now) -> StatsResult {
        var r = StatsResult()

        let owned = records.filter { $0.status == .owned }
        let wantlist = records.filter { $0.status == .wishlist }
        r.ownedCount = owned.count
        r.wantlistCount = wantlist.count

        // Value & spend (owned only).
        r.collectionValue = (owned.reduce(0.0) { $0 + max(0, $1.estValue) } * 100).rounded() / 100
        r.totalPaid = (owned.reduce(0.0) { $0 + max(0, $1.pricePaid) } * 100).rounded() / 100

        // Spins.
        let allSpins = owned.flatMap { $0.spins }
        r.totalSpins = allSpins.count
        let cal = Calendar.current
        r.spinsThisMonth = allSpins.filter { cal.isDate($0.date, equalTo: now, toGranularity: .month) }.count
        r.neverSpunCount = owned.filter { $0.spins.isEmpty }.count

        // Average tracklist length (owned with tracklists).
        let withTracks = owned.filter { !$0.tracks.isEmpty }
        if !withTracks.isEmpty {
            let total = withTracks.reduce(0) { $0 + $1.tracks.count }
            r.averageTrackCount = (Double(total) / Double(withTracks.count) * 10).rounded() / 10
        }

        // By genre.
        var genreMap: [Genre: Int] = [:]
        for rec in owned { genreMap[rec.genre, default: 0] += 1 }
        r.byGenre = genreMap
            .map { CategoryCount(label: $0.key.rawValue, count: $0.value, genre: $0.key) }
            .sorted { $0.count > $1.count }

        // By decade.
        var decadeMap: [Int: Int] = [:]
        for rec in owned {
            guard let d = rec.decade else { continue }
            decadeMap[d, default: 0] += 1
        }
        r.byDecade = decadeMap
            .map { CategoryCount(label: "\($0.key)s", count: $0.value, genre: nil) }
            .sorted { ($0.label) < ($1.label) }

        // By format.
        var formatMap: [Format: Int] = [:]
        for rec in owned { formatMap[rec.format, default: 0] += 1 }
        r.byFormat = formatMap
            .map { CategoryCount(label: $0.key.display, count: $0.value, genre: nil) }
            .sorted { $0.count > $1.count }

        // Condition breakdown (media condition), ordered best→worst.
        var condMap: [Grade: Int] = [:]
        for rec in owned { condMap[rec.mediaCondition, default: 0] += 1 }
        r.byCondition = Grade.allCases.compactMap { grade in
            let c = condMap[grade] ?? 0
            return c > 0 ? CategoryCount(label: grade.abbreviation, count: c, genre: nil) : nil
        }

        // Value by genre.
        var valueMap: [Genre: Double] = [:]
        for rec in owned { valueMap[rec.genre, default: 0] += max(0, rec.estValue) }
        r.valueByGenre = valueMap
            .map { CategoryValue(label: $0.key.rawValue, value: ($0.value * 100).rounded() / 100, genre: $0.key) }
            .filter { $0.value > 0 }
            .sorted { $0.value > $1.value }

        // Spins over time — last 12 months, oldest→newest.
        r.spinsOverTime = spinsSeries(spins: allSpins, now: now, months: 12, calendar: cal)

        // Most spun (owned with ≥1 spin), top 8.
        r.mostSpun = owned
            .filter { !$0.spins.isEmpty }
            .map { SpinRanked(id: $0.id, title: $0.title, artist: $0.artist,
                              coverHue: $0.coverHue, spins: $0.spins.count) }
            .sorted { $0.spins > $1.spins }
            .prefix(8)
            .map { $0 }

        return r
    }

    /// Build a monthly spin count series across the trailing `months` window.
    private static func spinsSeries(spins: [Spin], now: Date, months: Int, calendar cal: Calendar) -> [MonthPoint] {
        guard months > 0 else { return [] }
        let comps = cal.dateComponents([.year, .month], from: now)
        guard let thisMonthStart = cal.date(from: comps) else { return [] }

        // Bucket boundaries oldest→newest.
        var buckets: [Date] = []
        for offset in stride(from: months - 1, through: 0, by: -1) {
            if let d = cal.date(byAdding: .month, value: -offset, to: thisMonthStart) {
                buckets.append(d)
            }
        }
        guard !buckets.isEmpty else { return [] }

        var counts = Array(repeating: 0, count: buckets.count)
        for s in spins {
            let sc = cal.dateComponents([.year, .month], from: s.date)
            guard let sMonth = cal.date(from: sc) else { continue }
            if let idx = buckets.firstIndex(where: { cal.isDate($0, equalTo: sMonth, toGranularity: .month) }) {
                counts[idx] += 1
            }
        }
        return buckets.enumerated().map { MonthPoint(month: $0.element, count: counts[$0.offset]) }
    }
}

import Foundation

/// A labelled count used by charts and lists.
struct NamedCount: Identifiable {
    let id = UUID()
    let label: String
    let count: Int
}

/// Shows logged in a given year.
struct YearCount: Identifiable {
    let id = UUID()
    let year: Int
    let count: Int
    var label: String { String(year) }
}

/// Total ticket spend in a given year.
struct YearSpend: Identifiable {
    let id = UUID()
    let year: Int
    let total: Decimal
    var label: String { String(year) }
}

/// One upcoming wishlist show with its countdown.
struct UpcomingShow: Identifiable {
    let id: UUID
    let headliner: String
    let venueLine: String
    let date: Date
    let daysUntil: Int
}

/// The full computed statistics for a fan's attended history.
struct ConcertStats {
    var totalAttended: Int = 0
    var distinctArtists: Int = 0
    var distinctVenues: Int = 0
    var distinctCities: Int = 0
    var distinctCountries: Int = 0

    var mostSeenArtist: NamedCount?
    var mostVisitedVenue: NamedCount?

    var showsPerYear: [YearCount] = []
    var spendPerYear: [YearSpend] = []

    var totalSpent: Decimal = 0
    var averageRating: Double = 0      // 0 when no ratings
    var ratedCount: Int = 0

    var topArtists: [NamedCount] = []
    var topVenues: [NamedCount] = []
    var genreCounts: [NamedCount] = []

    var busiestYear: Int?
    var firstShowDate: Date?
    var totalSongsLogged: Int = 0

    var upcoming: [UpcomingShow] = []

    var isEmpty: Bool { totalAttended == 0 && upcoming.isEmpty }
}

/// Pure, fully guarded statistics engine. No SwiftUI, no side effects.
enum ConcertStatsEngine {

    static func compute(concerts: [Concert]) -> ConcertStats {
        var stats = ConcertStats()

        let attended = concerts.filter { $0.status == .attended }
        stats.totalAttended = attended.count

        // MARK: Distinct artists (headliners + support names, case-insensitive)
        var artistKeys = Set<String>()
        var artistCounts: [String: (display: String, count: Int)] = [:]
        for c in attended {
            register(name: c.headliner, into: &artistKeys, counts: &artistCounts)
            for act in c.supportActs {
                register(name: act.name, into: &artistKeys, counts: &artistCounts)
            }
        }
        stats.distinctArtists = artistKeys.count

        // MARK: Distinct venues / cities / countries
        stats.distinctVenues = distinctCount(attended.map { $0.venueName })
        stats.distinctCities = distinctCount(attended.map { $0.city })
        stats.distinctCountries = distinctCount(attended.map { $0.country })

        // MARK: Top artists + most seen
        let sortedArtists = artistCounts.values
            .map { NamedCount(label: $0.display, count: $0.count) }
            .sorted { lhs, rhs in
                if lhs.count != rhs.count { return lhs.count > rhs.count }
                return lhs.label.localizedCaseInsensitiveCompare(rhs.label) == .orderedAscending
            }
        stats.topArtists = Array(sortedArtists.prefix(8))
        stats.mostSeenArtist = sortedArtists.first(where: { $0.count > 0 })

        // MARK: Top venues + most visited
        var venueCounts: [String: (display: String, count: Int)] = [:]
        for c in attended {
            let trimmed = c.venueName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            let key = trimmed.lowercased()
            let prior = venueCounts[key]?.count ?? 0
            venueCounts[key] = (display: venueCounts[key]?.display ?? trimmed, count: prior + 1)
        }
        let sortedVenues = venueCounts.values
            .map { NamedCount(label: $0.display, count: $0.count) }
            .sorted { lhs, rhs in
                if lhs.count != rhs.count { return lhs.count > rhs.count }
                return lhs.label.localizedCaseInsensitiveCompare(rhs.label) == .orderedAscending
            }
        stats.topVenues = Array(sortedVenues.prefix(8))
        stats.mostVisitedVenue = sortedVenues.first(where: { $0.count > 0 })

        // MARK: Shows per year + spend per year
        var yearShowMap: [Int: Int] = [:]
        var yearSpendMap: [Int: Decimal] = [:]
        var totalSpent: Decimal = 0
        for c in attended {
            let y = c.year
            yearShowMap[y, default: 0] += 1
            yearSpendMap[y, default: 0] += c.ticketPrice
            totalSpent += c.ticketPrice
        }
        stats.showsPerYear = yearShowMap
            .map { YearCount(year: $0.key, count: $0.value) }
            .sorted { $0.year < $1.year }
        stats.spendPerYear = yearSpendMap
            .map { YearSpend(year: $0.key, total: $0.value) }
            .sorted { $0.year < $1.year }
        stats.totalSpent = totalSpent

        // MARK: Busiest year (most shows; ties → most recent)
        stats.busiestYear = stats.showsPerYear
            .max { lhs, rhs in
                if lhs.count != rhs.count { return lhs.count < rhs.count }
                return lhs.year < rhs.year
            }?.year

        // MARK: Average rating (only over rated shows)
        let ratings = attended.compactMap { $0.rating }
        stats.ratedCount = ratings.count
        if !ratings.isEmpty {
            let sum = ratings.reduce(0, +)
            stats.averageRating = (sum / Double(ratings.count) * 10).rounded() / 10
        }

        // MARK: Genre counts (across attended)
        var genreMap: [String: Int] = [:]
        for c in attended {
            for g in c.genres {
                let key = g.name.trimmingCharacters(in: .whitespaces)
                guard !key.isEmpty else { continue }
                genreMap[key, default: 0] += 1
            }
        }
        stats.genreCounts = genreMap
            .map { NamedCount(label: $0.key, count: $0.value) }
            .sorted { lhs, rhs in
                if lhs.count != rhs.count { return lhs.count > rhs.count }
                return lhs.label.localizedCaseInsensitiveCompare(rhs.label) == .orderedAscending
            }

        // MARK: First show + total songs
        stats.firstShowDate = attended.map { $0.date }.min()
        stats.totalSongsLogged = attended.reduce(0) { $0 + $1.setlist.count }

        // MARK: Upcoming (wishlist with future date), nearest first
        stats.upcoming = concerts
            .filter { $0.isUpcoming }
            .compactMap { c in
                guard let days = c.daysUntil else { return nil }
                return UpcomingShow(id: c.id,
                                    headliner: c.headliner,
                                    venueLine: c.locationLine,
                                    date: c.date,
                                    daysUntil: days)
            }
            .sorted { $0.date < $1.date }

        return stats
    }

    // MARK: - Helpers

    private static func register(name: String,
                                 into keys: inout Set<String>,
                                 counts: inout [String: (display: String, count: Int)]) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let key = trimmed.lowercased()
        keys.insert(key)
        let prior = counts[key]?.count ?? 0
        counts[key] = (display: counts[key]?.display ?? trimmed, count: prior + 1)
    }

    private static func distinctCount(_ values: [String]) -> Int {
        var set = Set<String>()
        for v in values {
            let key = v.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            guard !key.isEmpty else { continue }
            set.insert(key)
        }
        return set.count
    }
}

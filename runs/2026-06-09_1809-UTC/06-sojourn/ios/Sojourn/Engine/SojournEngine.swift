import Foundation

/// Pure, static analytics over a set of `VisitMark`s plus the static
/// `CountryData`. No SwiftData, no UI. Every function guards empty inputs and
/// divide-by-zero so callers never crash.
enum SojournEngine {

    // MARK: - Types

    struct WorldProgress {
        let groundedCount: Int          // visited or lived (+ transit if counted)
        let total: Int                  // total countries in the dataset
        let percent: Double             // 0…1
        let continentsTouched: Int      // distinct continents with ≥1 grounded
        let continentTotal: Int         // always 6
    }

    struct ContinentProgress: Identifiable {
        let continent: Continent
        let grounded: Int
        let total: Int
        var id: String { continent.rawValue }
        var fraction: Double { total > 0 ? Double(grounded) / Double(total) : 0 }
    }

    struct RegionProgress: Identifiable {
        let region: String
        let grounded: Int
        let total: Int
        var id: String { region }
        var fraction: Double { total > 0 ? Double(grounded) / Double(total) : 0 }
    }

    struct YearPoint: Identifiable {
        let year: Int
        let count: Int
        var id: Int { year }
    }

    struct StatusSlice: Identifiable {
        let status: VisitStatus
        let count: Int
        var id: String { status.rawValue }
    }

    struct Passport {
        let totalMarked: Int
        let favorites: Int
        let mostVisited: VisitMark?      // max timesVisited (grounded)
        let mostRecent: VisitMark?       // latest createdAt
    }

    // MARK: - Helpers

    /// Whether a mark counts toward world progress, honoring the transit
    /// preference. Wishlist never counts.
    static func counts(_ mark: VisitMark, countTransit: Bool) -> Bool {
        switch mark.status {
        case .visited, .lived: return true
        case .transit: return countTransit
        case .wishlist: return false
        }
    }

    /// Codes the user has been to (grounded, honoring transit pref). Excludes a
    /// provided home code so the home country never inflates "places seen".
    static func groundedCodes(_ marks: [VisitMark], countTransit: Bool, excluding homeCode: String? = nil) -> Set<String> {
        var set = Set<String>()
        let home = homeCode?.uppercased()
        for m in marks where counts(m, countTransit: countTransit) {
            let code = m.countryCode.uppercased()
            if let home, code == home { continue }
            set.insert(code)
        }
        return set
    }

    // MARK: - World progress

    static func worldProgress(_ marks: [VisitMark], countTransit: Bool, homeCode: String? = nil) -> WorldProgress {
        let codes = groundedCodes(marks, countTransit: countTransit, excluding: homeCode)
        let total = CountryData.total
        let percent = total > 0 ? Double(codes.count) / Double(total) : 0
        let continents = Set(codes.compactMap { CountryData.country(for: $0)?.continent })
        return WorldProgress(groundedCount: codes.count,
                             total: total,
                             percent: percent,
                             continentsTouched: continents.count,
                             continentTotal: Continent.allCases.count)
    }

    /// Count of marks per status (every status appears, even at zero).
    static func statusCounts(_ marks: [VisitMark]) -> [VisitStatus: Int] {
        var out: [VisitStatus: Int] = [:]
        for status in VisitStatus.allCases { out[status] = 0 }
        for m in marks { out[m.status, default: 0] += 1 }
        return out
    }

    static func statusDistribution(_ marks: [VisitMark]) -> [StatusSlice] {
        let counts = statusCounts(marks)
        return VisitStatus.allCases
            .map { StatusSlice(status: $0, count: counts[$0] ?? 0) }
            .filter { $0.count > 0 }
    }

    // MARK: - Continent / region breakdown

    static func continentBreakdown(_ marks: [VisitMark], countTransit: Bool, homeCode: String? = nil) -> [ContinentProgress] {
        let codes = groundedCodes(marks, countTransit: countTransit, excluding: homeCode)
        return Continent.allCases.map { continent in
            let total = continent.totalCountries
            let grounded = codes.filter { CountryData.country(for: $0)?.continent == continent }.count
            return ContinentProgress(continent: continent, grounded: grounded, total: total)
        }
    }

    /// Regions with at least one country grounded, sorted most-explored first.
    static func regionBreakdown(_ marks: [VisitMark], countTransit: Bool, homeCode: String? = nil) -> [RegionProgress] {
        let codes = groundedCodes(marks, countTransit: countTransit, excluding: homeCode)
        guard !codes.isEmpty else { return [] }
        // Totals per region from the dataset.
        var totals: [String: Int] = [:]
        for c in CountryData.all { totals[c.region, default: 0] += 1 }
        var grounded: [String: Int] = [:]
        for code in codes {
            if let region = CountryData.country(for: code)?.region {
                grounded[region, default: 0] += 1
            }
        }
        return grounded.map { region, count in
            RegionProgress(region: region, grounded: count, total: totals[region] ?? count)
        }
        .sorted { $0.grounded > $1.grounded }
    }

    // MARK: - Timeline / distributions

    /// Visited-by-year series from `firstVisitYear`, oldest → newest, only for
    /// marks that count. Years with no first-visit value are skipped.
    static func visitedByYear(_ marks: [VisitMark], countTransit: Bool) -> [YearPoint] {
        var byYear: [Int: Int] = [:]
        for m in marks where counts(m, countTransit: countTransit) {
            if let year = m.firstVisitYear { byYear[year, default: 0] += 1 }
        }
        return byYear.keys.sorted().map { YearPoint(year: $0, count: byYear[$0] ?? 0) }
    }

    // MARK: - Wishlist

    static func wishlist(_ marks: [VisitMark]) -> [VisitMark] {
        marks.filter { $0.status == .wishlist }
            .sorted { $0.createdAt < $1.createdAt }
    }

    static func wishlistCount(_ marks: [VisitMark]) -> Int {
        marks.lazy.filter { $0.status == .wishlist }.count
    }

    // MARK: - Passport summary

    static func passport(_ marks: [VisitMark]) -> Passport {
        let favorites = marks.lazy.filter { $0.isFavorite }.count
        let grounded = marks.filter { $0.isGrounded }
        let mostVisited = grounded.max { $0.timesVisited < $1.timesVisited }
        let mostRecent = marks.max { $0.createdAt < $1.createdAt }
        return Passport(totalMarked: marks.count,
                        favorites: favorites,
                        mostVisited: (mostVisited?.timesVisited ?? 0) > 0 ? mostVisited : nil,
                        mostRecent: mostRecent)
    }

    /// Most recent marks (by createdAt), newest first, capped at `limit`.
    static func recentMarks(_ marks: [VisitMark], limit: Int = 6) -> [VisitMark] {
        Array(marks.sorted { $0.createdAt > $1.createdAt }.prefix(limit))
    }

    /// Count of grounded countries whose `firstVisitYear` is the current year.
    static func groundedThisYear(_ marks: [VisitMark], countTransit: Bool, now: Date = .now) -> Int {
        let year = Calendar.current.component(.year, from: now)
        return marks.lazy.filter { counts($0, countTransit: countTransit) && $0.firstVisitYear == year }.count
    }
}

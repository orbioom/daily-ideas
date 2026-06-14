import Foundation

// MARK: - Value types consumed by Charts & stats views (Identifiable structs, never tuples)

struct StatusCount: Identifiable {
    var id: String { status.rawValue }
    let status: GameStatus
    let count: Int
}

struct PlatformStat: Identifiable {
    var id: String { platform.rawValue }
    let platform: Platform
    let count: Int
    let hours: Double
}

struct GenreStat: Identifiable {
    var id: String { genre.rawValue }
    let genre: Genre
    let count: Int
}

struct MonthlyStat: Identifiable {
    var id: Int { monthIndex }
    let monthIndex: Int      // 0...11
    let label: String        // "Jan"
    let beaten: Int
    let hours: Double
}

struct RatingBucket: Identifiable {
    var id: Int { rating }
    let rating: Int          // 1...10
    let count: Int
}

struct YearChallenge {
    let goal: Int
    let beaten: Int
    let year: Int
    /// Fraction of the year elapsed, 0...1.
    let yearFraction: Double

    var progress: Double {
        guard goal > 0 else { return 0 }
        return min(1, Double(beaten) / Double(goal))
    }

    /// Games we "should" have beaten by now to be on pace.
    var expectedByNow: Double { Double(goal) * yearFraction }

    /// Positive = ahead, negative = behind (rounded games).
    var paceDelta: Int { beaten - Int(expectedByNow.rounded()) }

    var isOnTrack: Bool { Double(beaten) >= expectedByNow }

    /// Projected total at current pace.
    var projectedTotal: Int {
        guard yearFraction > 0 else { return beaten }
        return Int((Double(beaten) / yearFraction).rounded())
    }
}

struct PickFilters {
    var platform: Platform? = nil
    var genre: Genre? = nil
    var maxHours: Double? = nil      // nil = no cap
    var favoritesOnly: Bool = false
    var weighting: PickWeighting = .even
}

enum PickWeighting: String, CaseIterable, Identifiable {
    case even
    case shortest
    case favorites

    var id: String { rawValue }
    var label: String {
        switch self {
        case .even: return "Even odds"
        case .shortest: return "Favor short games"
        case .favorites: return "Favor favorites"
        }
    }
}

/// Pure, side-effect-free analytics over a games array. Never mutates models.
enum BacklogEngine {

    // MARK: Status

    static func statusCounts(_ games: [Game]) -> [StatusCount] {
        GameStatus.allCases.map { status in
            StatusCount(status: status, count: games.filter { $0.status == status }.count)
        }
    }

    /// Completion % = completed / (everything except wishlist), guarded.
    static func completionPercent(_ games: [Game]) -> Double {
        let owned = games.filter { $0.status != .wishlist }
        guard !owned.isEmpty else { return 0 }
        let done = owned.filter { $0.status == .completed }.count
        return Double(done) / Double(owned.count) * 100
    }

    static func totalHoursLogged(_ games: [Game]) -> Double {
        games.reduce(0) { $0 + $1.hoursLogged }
    }

    // MARK: Year challenge

    static func yearChallenge(_ games: [Game], goal: Int, now: Date = .now,
                              calendar: Calendar = .current) -> YearChallenge {
        let year = calendar.component(.year, from: now)
        let beaten = beatenThisYear(games, now: now, calendar: calendar).count

        // Fraction of the year elapsed.
        var fraction = 0.5
        if let startOfYear = calendar.date(from: DateComponents(year: year, month: 1, day: 1)),
           let startOfNext = calendar.date(from: DateComponents(year: year + 1, month: 1, day: 1)) {
            let total = startOfNext.timeIntervalSince(startOfYear)
            if total > 0 {
                fraction = min(1, max(0.0001, now.timeIntervalSince(startOfYear) / total))
            }
        }
        return YearChallenge(goal: max(0, goal), beaten: beaten, year: year, yearFraction: fraction)
    }

    static func beatenThisYear(_ games: [Game], now: Date = .now,
                               calendar: Calendar = .current) -> [Game] {
        let year = calendar.component(.year, from: now)
        return games.filter {
            $0.status == .completed
            && ($0.dateCompleted.map { calendar.component(.year, from: $0) == year } ?? false)
        }
        .sorted { ($0.dateCompleted ?? .distantPast) > ($1.dateCompleted ?? .distantPast) }
    }

    // MARK: Breakdowns

    static func platformStats(_ games: [Game]) -> [PlatformStat] {
        Platform.allCases.compactMap { platform in
            let subset = games.filter { $0.platform == platform }
            guard !subset.isEmpty else { return nil }
            let hours = subset.reduce(0) { $0 + $1.hoursLogged }
            return PlatformStat(platform: platform, count: subset.count, hours: hours)
        }
        .sorted { $0.count > $1.count }
    }

    static func genreStats(_ games: [Game]) -> [GenreStat] {
        Genre.allCases.compactMap { genre in
            let count = games.filter { $0.genre == genre }.count
            guard count > 0 else { return nil }
            return GenreStat(genre: genre, count: count)
        }
        .sorted { $0.count > $1.count }
    }

    static func ratingDistribution(_ games: [Game]) -> [RatingBucket] {
        (1...10).map { r in
            RatingBucket(rating: r, count: games.filter { $0.personalRating == r }.count)
        }
    }

    /// Beaten-per-month and hours-per-month for the current year.
    static func monthlyStats(_ games: [Game], now: Date = .now,
                             calendar: Calendar = .current) -> [MonthlyStat] {
        let year = calendar.component(.year, from: now)
        let monthLabels = calendar.shortMonthSymbols
        var beatenByMonth = Array(repeating: 0, count: 12)
        var hoursByMonth = Array(repeating: 0.0, count: 12)

        for game in games {
            if game.status == .completed,
               let dc = game.dateCompleted,
               calendar.component(.year, from: dc) == year {
                let m = calendar.component(.month, from: dc) - 1
                if m >= 0 && m < 12 { beatenByMonth[m] += 1 }
            }
            for session in game.sessions where calendar.component(.year, from: session.date) == year {
                let m = calendar.component(.month, from: session.date) - 1
                if m >= 0 && m < 12 { hoursByMonth[m] += max(0, session.hours) }
            }
        }

        return (0..<12).map { i in
            let label = (i < monthLabels.count) ? monthLabels[i] : "M\(i + 1)"
            return MonthlyStat(monthIndex: i, label: label,
                               beaten: beatenByMonth[i], hours: hoursByMonth[i])
        }
    }

    // MARK: Pick next

    /// Candidate backlog games matching the filters.
    static func pickCandidates(_ games: [Game], filters: PickFilters) -> [Game] {
        games.filter { game in
            guard game.status == .backlog else { return false }
            if let p = filters.platform, game.platform != p { return false }
            if let g = filters.genre, game.genre != g { return false }
            if let cap = filters.maxHours, cap > 0 {
                // Unknown length (0) is always allowed; known lengths must fit.
                if game.mainStoryHours > 0 && game.mainStoryHours > cap { return false }
            }
            if filters.favoritesOnly && !game.isFavorite { return false }
            return true
        }
    }

    /// Weighted random pick using a seeded RNG so the result is stable for a seed.
    static func pickNext(_ games: [Game], filters: PickFilters, seed: UInt64) -> Game? {
        let candidates = pickCandidates(games, filters: filters)
        guard !candidates.isEmpty else { return nil }

        let weights: [Double] = candidates.map { game in
            switch filters.weighting {
            case .even:
                return 1
            case .shortest:
                // Shorter known games weigh more; unknown length gets a neutral mid weight.
                if game.mainStoryHours <= 0 { return 1 }
                return 1 + 40 / (game.mainStoryHours + 4)
            case .favorites:
                return game.isFavorite ? 4 : 1
            }
        }

        let total = weights.reduce(0, +)
        guard total > 0 else { return candidates.first }

        var rng = SeededRNG(seed: seed)
        let roll = Double(rng.next() % 1_000_000) / 1_000_000.0 * total
        var running = 0.0
        for (index, w) in weights.enumerated() {
            running += w
            if roll < running { return candidates[index] }
        }
        return candidates.last
    }
}

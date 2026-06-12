import Foundation

struct StatusCount: Identifiable { let status: GameStatus; let count: Int; var id: GameStatus { status } }
struct GenreCount: Identifiable { let genre: Genre; let count: Int; var id: Genre { genre } }
struct PlatformCount: Identifiable { let platform: Platform; let count: Int; var id: Platform { platform } }

/// Pure statistics over a game library. No state.
enum BacklogEngine {

    static func count(_ games: [Game], status: GameStatus) -> Int {
        games.filter { $0.status == status }.count
    }

    static func totalHoursPlayed(_ games: [Game]) -> Double {
        games.reduce(0) { $0 + $1.hoursPlayed }
    }

    static func totalSpend(_ games: [Game]) -> Double {
        games.reduce(0) { $0 + $1.pricePaid }
    }

    /// Cost per hour played across games you actually paid for and played.
    static func costPerHour(_ games: [Game]) -> Double? {
        let hours = totalHoursPlayed(games)
        let spend = totalSpend(games)
        guard hours > 0, spend > 0 else { return nil }
        return spend / hours
    }

    /// Finished ÷ (everything you own or have touched, excluding wishlist).
    static func completionRate(_ games: [Game]) -> Double {
        let owned = games.filter { $0.status != .wishlist }
        guard !owned.isEmpty else { return 0 }
        let finished = owned.filter { $0.status.isFinished }.count
        return Double(finished) / Double(owned.count)
    }

    static func averageRating(_ games: [Game]) -> Double? {
        let rated = games.filter { $0.ratingHalf > 0 }
        guard !rated.isEmpty else { return nil }
        return rated.reduce(0.0) { $0 + $1.rating } / Double(rated.count)
    }

    /// Pile size (owned, unfinished) and the estimated hours to clear it.
    static func pileSize(_ games: [Game]) -> Int {
        games.filter { $0.status.isPile }.count
    }
    static func pileHoursRemaining(_ games: [Game]) -> Double {
        games.filter { $0.status.isPile }.reduce(0) { $0 + $1.hoursRemaining }
    }

    static func byStatus(_ games: [Game]) -> [StatusCount] {
        GameStatus.allCases.map { StatusCount(status: $0, count: count(games, status: $0)) }
            .filter { $0.count > 0 }
    }

    static func byGenre(_ games: [Game]) -> [GenreCount] {
        var d = [Genre: Int]()
        for g in games where g.status != .wishlist { d[g.genre, default: 0] += 1 }
        return d.map { GenreCount(genre: $0.key, count: $0.value) }.sorted { $0.count > $1.count }
    }

    static func byPlatform(_ games: [Game]) -> [PlatformCount] {
        var d = [Platform: Int]()
        for g in games where g.status != .wishlist { d[g.platform, default: 0] += 1 }
        return d.map { PlatformCount(platform: $0.key, count: $0.value) }.sorted { $0.count > $1.count }
    }

    /// Pick the best "play next" candidate: highest priority among the pile,
    /// breaking ties by least time remaining (quick wins first), then oldest add.
    static func nextUp(_ games: [Game]) -> Game? {
        games.filter { $0.status.isPile }
            .sorted { a, b in
                if a.priorityRaw != b.priorityRaw { return a.priorityRaw > b.priorityRaw }
                if a.hoursRemaining != b.hoursRemaining { return a.hoursRemaining < b.hoursRemaining }
                return a.dateAdded < b.dateAdded
            }
            .first
    }
}

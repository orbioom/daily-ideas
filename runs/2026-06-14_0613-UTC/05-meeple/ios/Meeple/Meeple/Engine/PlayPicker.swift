import Foundation

/// Filters owned games for a game-night and produces a stable seeded random pick.
struct PlayPickerCriteria: Equatable {
    var playerCount: Int
    var maxDuration: Int          // minutes; 0 = no limit
    var minWeight: Double
    var maxWeight: Double

    static let `default` = PlayPickerCriteria(
        playerCount: 3, maxDuration: 0, minWeight: 1.0, maxWeight: 5.0
    )
}

enum PlayPicker {

    /// Eligible owned games matching the criteria, sorted by rating then title.
    static func eligible(_ games: [BoardGame], criteria: PlayPickerCriteria) -> [BoardGame] {
        games.filter { g in
            guard g.status == .owned else { return false }
            let supportsCount = g.minPlayers <= criteria.playerCount
                && criteria.playerCount <= g.maxPlayers
            guard supportsCount else { return false }
            if criteria.maxDuration > 0, g.playTimeMin > criteria.maxDuration { return false }
            guard g.weight >= criteria.minWeight, g.weight <= criteria.maxWeight else { return false }
            return true
        }
        .sorted { lhs, rhs in
            if lhs.rating != rhs.rating { return lhs.rating > rhs.rating }
            return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
        }
    }

    /// A deterministic pick from the eligible set for a given seed.
    /// Re-rolling with a new seed yields a (likely) different stable result.
    /// Returns nil when nothing is eligible.
    static func pick(_ games: [BoardGame], criteria: PlayPickerCriteria, seed: UInt64) -> BoardGame? {
        let pool = eligible(games, criteria: criteria)
        guard !pool.isEmpty else { return nil }
        let index = Int(seed % UInt64(pool.count))
        return pool[index]
    }
}

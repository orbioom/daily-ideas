import Foundation

// MARK: - Result value types (Identifiable for Swift Charts)

struct MostPlayedEntry: Identifiable {
    let id: UUID
    let title: String
    let count: Int
}

struct MonthlyPlays: Identifiable {
    let id = UUID()
    let month: Date          // first of month
    let count: Int
    var label: String {
        month.formatted(.dateTime.month(.abbreviated).year(.twoDigits))
    }
}

struct PlayerWinRate: Identifiable {
    let id: UUID
    let name: String
    let colorHue: Int
    let playsWithResults: Int
    let wins: Int
    /// 0...1; guarded — 0 when no qualifying plays.
    var rate: Double {
        guard playsWithResults > 0 else { return 0 }
        return Double(wins) / Double(playsWithResults)
    }
    var ratePercentText: String {
        guard playsWithResults > 0 else { return "—" }
        return "\(Int((rate * 100).rounded()))%"
    }
}

struct WeightBucket: Identifiable {
    let id = UUID()
    let label: String        // "1–2", "2–3", ...
    let count: Int
}

struct StatusCount: Identifiable {
    let id = UUID()
    let status: CollectionStatus
    let count: Int
}

struct PlayerCountCoverage: Identifiable {
    let id = UUID()
    let players: Int         // e.g. 2,3,4...
    let count: Int           // owned games that support this count
}

/// Aggregated, ready-to-render statistics.
struct StatsSnapshot {
    var totalPlays: Int = 0
    var uniqueGamesPlayed: Int = 0
    var newToMeCount: Int = 0        // games with exactly one play
    var totalHours: Double = 0
    var averageWeightPlayed: Double = 0
    var hIndex: Int = 0
    var mostPlayed: [MostPlayedEntry] = []
    var monthly: [MonthlyPlays] = []
    var playerWinRates: [PlayerWinRate] = []
    var weightDistribution: [WeightBucket] = []
    var statusCounts: [StatusCount] = []
    var playerCountCoverage: [PlayerCountCoverage] = []
    var ownedCount: Int = 0

    static let empty = StatsSnapshot()
}

/// Pure stats computation. No SwiftUI / SwiftData imports — operates on fetched arrays.
enum StatsEngine {

    /// Compute everything from the full game list (plays are reached via relationship).
    static func compute(games: [BoardGame], roster: [Player]) -> StatsSnapshot {
        var snap = StatsSnapshot()

        // Flatten plays.
        let allPlays: [Play] = games.flatMap { $0.plays }
        snap.totalPlays = allPlays.count
        snap.ownedCount = games.filter { $0.status == .owned }.count

        // Per-game play counts.
        let gamePlayCounts: [(game: BoardGame, count: Int)] = games
            .map { ($0, $0.plays.count) }
            .filter { $0.1 > 0 }

        snap.uniqueGamesPlayed = gamePlayCounts.count
        snap.newToMeCount = gamePlayCounts.filter { $0.count == 1 }.count

        // Total hours (guard zero durations gracefully).
        let totalMinutes = allPlays.reduce(0) { $0 + max(0, $1.durationMin) }
        snap.totalHours = Double(totalMinutes) / 60.0

        // Average weight of games actually played, weighted by play count.
        var weightSum = 0.0
        var weightN = 0
        for entry in gamePlayCounts {
            weightSum += entry.game.weight * Double(entry.count)
            weightN += entry.count
        }
        snap.averageWeightPlayed = weightN > 0 ? weightSum / Double(weightN) : 0

        // H-index: largest N such that N games each played >= N times.
        let countsDesc = gamePlayCounts.map(\.count).sorted(by: >)
        var h = 0
        for (i, c) in countsDesc.enumerated() {
            if c >= i + 1 { h = i + 1 } else { break }
        }
        snap.hIndex = h

        // Most-played (top 8).
        snap.mostPlayed = gamePlayCounts
            .sorted { $0.count > $1.count }
            .prefix(8)
            .map { MostPlayedEntry(id: $0.game.id, title: $0.game.title, count: $0.count) }

        // Plays per month over the last 12 months.
        snap.monthly = monthlySeries(plays: allPlays)

        // Per-player win rates.
        snap.playerWinRates = winRates(plays: allPlays, roster: roster)

        // Weight distribution across owned games.
        snap.weightDistribution = weightBuckets(games: games.filter { $0.status == .owned })

        // Status counts.
        snap.statusCounts = CollectionStatus.allCases.map { status in
            StatusCount(status: status, count: games.filter { $0.status == status }.count)
        }

        // Player-count coverage among owned games (2...8).
        snap.playerCountCoverage = (2...8).map { n in
            let c = games.filter { $0.status == .owned && $0.minPlayers <= n && n <= $0.maxPlayers }.count
            return PlayerCountCoverage(players: n, count: c)
        }

        return snap
    }

    // MARK: - Helpers

    private static func monthlySeries(plays: [Play]) -> [MonthlyPlays] {
        let cal = Calendar.current
        let now = Date()
        // Build the last 12 month-anchors (oldest first).
        var anchors: [Date] = []
        for back in stride(from: 11, through: 0, by: -1) {
            if let d = cal.date(byAdding: .month, value: -back, to: now),
               let start = cal.date(from: cal.dateComponents([.year, .month], from: d)) {
                anchors.append(start)
            }
        }
        // Bucket plays.
        var buckets: [Date: Int] = [:]
        for p in plays {
            if let start = cal.date(from: cal.dateComponents([.year, .month], from: p.date)) {
                buckets[start, default: 0] += 1
            }
        }
        return anchors.map { MonthlyPlays(month: $0, count: buckets[$0] ?? 0) }
    }

    private static func winRates(plays: [Play], roster: [Player]) -> [PlayerWinRate] {
        // Tally by player name snapshot. Only count plays that have results.
        var played: [String: Int] = [:]
        var won: [String: Int] = [:]
        var hueFor: [String: Int] = [:]

        for play in plays where !play.results.isEmpty {
            for r in play.results {
                played[r.playerName, default: 0] += 1
                if r.isWinner { won[r.playerName, default: 0] += 1 }
                if hueFor[r.playerName] == nil { hueFor[r.playerName] = r.colorHue }
            }
        }
        // Prefer roster hue / order when available.
        let rosterByName = Dictionary(roster.map { ($0.name, $0) }, uniquingKeysWith: { a, _ in a })

        let names = Set(played.keys).union(rosterByName.keys)
        var rates: [PlayerWinRate] = names.map { name in
            let p = played[name] ?? 0
            let w = won[name] ?? 0
            let hue = rosterByName[name]?.colorHue ?? hueFor[name] ?? Player.hue(for: name)
            let id = rosterByName[name]?.id ?? UUID()
            return PlayerWinRate(id: id, name: name, colorHue: hue, playsWithResults: p, wins: w)
        }
        // Only show players who actually have qualifying plays, sorted by rate then plays.
        rates = rates.filter { $0.playsWithResults > 0 }
        rates.sort { lhs, rhs in
            if lhs.rate != rhs.rate { return lhs.rate > rhs.rate }
            return lhs.playsWithResults > rhs.playsWithResults
        }
        return rates
    }

    private static func weightBuckets(games: [BoardGame]) -> [WeightBucket] {
        let ranges: [(String, Range<Double>)] = [
            ("1–2", 1.0..<2.0),
            ("2–3", 2.0..<3.0),
            ("3–4", 3.0..<4.0),
            ("4–5", 4.0..<5.01)
        ]
        return ranges.map { (label, range) in
            WeightBucket(label: label, count: games.filter { range.contains($0.weight) }.count)
        }
    }

    // MARK: - Per-game stats

    struct GameStats {
        var timesPlayed: Int = 0
        var lastPlayed: Date?
        var averageDuration: Int = 0
        var perPlayer: [PlayerWinRate] = []
    }

    static func gameStats(_ game: BoardGame) -> GameStats {
        var gs = GameStats()
        let plays = game.plays
        gs.timesPlayed = plays.count
        gs.lastPlayed = plays.map(\.date).max()

        let durations = plays.map(\.durationMin).filter { $0 > 0 }
        gs.averageDuration = durations.isEmpty ? 0 : durations.reduce(0, +) / durations.count

        var played: [String: Int] = [:]
        var won: [String: Int] = [:]
        var hueFor: [String: Int] = [:]
        for play in plays where !play.results.isEmpty {
            for r in play.results {
                played[r.playerName, default: 0] += 1
                if r.isWinner { won[r.playerName, default: 0] += 1 }
                if hueFor[r.playerName] == nil { hueFor[r.playerName] = r.colorHue }
            }
        }
        gs.perPlayer = played.keys.map { name in
            PlayerWinRate(
                id: UUID(),
                name: name,
                colorHue: hueFor[name] ?? Player.hue(for: name),
                playsWithResults: played[name] ?? 0,
                wins: won[name] ?? 0
            )
        }
        .sorted { lhs, rhs in
            if lhs.wins != rhs.wins { return lhs.wins > rhs.wins }
            return lhs.playsWithResults > rhs.playsWithResults
        }
        return gs
    }
}

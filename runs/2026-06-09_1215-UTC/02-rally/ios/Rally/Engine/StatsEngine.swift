import Foundation

/// Pure analytics over a set of matches for a given player. Everything is
/// computed on demand from completed matches — no derived state is persisted.
/// A player is "on my side" of a match if they appear in `mySide`; the engine
/// always reports results from that player's own perspective.
enum StatsEngine {

    // MARK: - Helpers

    /// Completed matches involving `player`, newest first.
    static func matches(for player: Player, in all: [Match]) -> [Match] {
        all.filter { $0.isComplete && involves(player, $0) }
            .sorted { $0.date > $1.date }
    }

    static func involves(_ player: Player, _ match: Match) -> Bool {
        match.mySide.contains { $0.persistentModelID == player.persistentModelID }
            || match.oppSide.contains { $0.persistentModelID == player.persistentModelID }
    }

    static func isOnMySide(_ player: Player, _ match: Match) -> Bool {
        match.mySide.contains { $0.persistentModelID == player.persistentModelID }
    }

    /// Did `player` win this match (from their own side's perspective)?
    static func didWin(_ player: Player, _ match: Match) -> Bool {
        isOnMySide(player, match) ? match.didWin : !match.didWin
    }

    // MARK: - Record

    struct Record {
        var wins: Int = 0
        var losses: Int = 0
        var total: Int { wins + losses }
        var winRate: Double { total == 0 ? 0 : Double(wins) / Double(total) }
        var winRatePercent: Int { Int((winRate * 100).rounded()) }
        var line: String { "\(wins)–\(losses)" }
    }

    static func record(for player: Player, in all: [Match]) -> Record {
        var r = Record()
        for m in matches(for: player, in: all) {
            if didWin(player, m) { r.wins += 1 } else { r.losses += 1 }
        }
        return r
    }

    static func record(for player: Player, sport: Sport, in all: [Match]) -> Record {
        var r = Record()
        for m in matches(for: player, in: all) where m.sport == sport {
            if didWin(player, m) { r.wins += 1 } else { r.losses += 1 }
        }
        return r
    }

    static func record(for player: Player, format: MatchFormat, in all: [Match]) -> Record {
        var r = Record()
        for m in matches(for: player, in: all) where m.format == format {
            if didWin(player, m) { r.wins += 1 } else { r.losses += 1 }
        }
        return r
    }

    // MARK: - Streak

    /// Current win/loss streak for `player`. Positive = wins, negative = losses,
    /// zero = no completed matches.
    static func currentStreak(for player: Player, in all: [Match]) -> Int {
        let ms = matches(for: player, in: all) // newest first
        guard let first = ms.first else { return 0 }
        let winning = didWin(player, first)
        var streak = 0
        for m in ms {
            if didWin(player, m) == winning { streak += 1 } else { break }
        }
        return winning ? streak : -streak
    }

    static func streakLabel(_ streak: Int) -> String {
        if streak > 0 { return "W\(streak)" }
        if streak < 0 { return "L\(-streak)" }
        return "—"
    }

    // MARK: - Head-to-head & partners

    /// `player`'s record specifically against `opponent`.
    static func headToHead(player: Player, opponent: Player, in all: [Match]) -> Record {
        var r = Record()
        for m in matches(for: player, in: all) {
            let oppSide = isOnMySide(player, m) ? m.oppSide : m.mySide
            let faced = oppSide.contains { $0.persistentModelID == opponent.persistentModelID }
            guard faced else { continue }
            if didWin(player, m) { r.wins += 1 } else { r.losses += 1 }
        }
        return r
    }

    struct Opponent: Identifiable {
        let player: Player
        let record: Record
        var id: PersistentIdentifier { player.persistentModelID }
    }

    /// Every opponent `player` has faced, with the head-to-head record, sorted by
    /// most-played.
    static func opponents(for player: Player, in all: [Match]) -> [Opponent] {
        var seen: [PersistentIdentifier: Player] = [:]
        for m in matches(for: player, in: all) {
            let oppSide = isOnMySide(player, m) ? m.oppSide : m.mySide
            for p in oppSide where p.persistentModelID != player.persistentModelID {
                seen[p.persistentModelID] = p
            }
        }
        return seen.values
            .map { Opponent(player: $0, record: headToHead(player: player, opponent: $0, in: all)) }
            .sorted { $0.record.total > $1.record.total }
    }

    struct Partner: Identifiable {
        let player: Player
        let record: Record
        var id: PersistentIdentifier { player.persistentModelID }
    }

    /// Doubles partners (players on the same side) and the record when paired.
    static func partners(for player: Player, in all: [Match]) -> [Partner] {
        var records: [PersistentIdentifier: (Player, Record)] = [:]
        for m in matches(for: player, in: all) where m.format == .doubles {
            let mine = isOnMySide(player, m) ? m.mySide : m.oppSide
            let won = didWin(player, m)
            for p in mine where p.persistentModelID != player.persistentModelID {
                var entry = records[p.persistentModelID] ?? (p, Record())
                if won { entry.1.wins += 1 } else { entry.1.losses += 1 }
                records[p.persistentModelID] = entry
            }
        }
        return records.values
            .map { Partner(player: $0.0, record: $0.1) }
            .sorted { $0.record.total > $1.record.total }
    }

    /// Best partner = the one with the highest win rate (min 2 matches together).
    static func bestPartner(for player: Player, in all: [Match]) -> Partner? {
        partners(for: player, in: all)
            .filter { $0.record.total >= 2 }
            .max { a, b in a.record.winRate < b.record.winRate }
    }

    // MARK: - Points

    static func pointsFor(_ player: Player, in all: [Match]) -> (scored: Int, conceded: Int) {
        var scored = 0
        var conceded = 0
        for m in matches(for: player, in: all) {
            if isOnMySide(player, m) {
                scored += m.myPoints; conceded += m.oppPoints
            } else {
                scored += m.oppPoints; conceded += m.myPoints
            }
        }
        return (scored, conceded)
    }

    // MARK: - Series

    struct MonthPoint: Identifiable {
        let date: Date          // first of month
        let count: Int
        var id: Date { date }
    }

    /// Matches per month for the last `months` months, oldest → newest.
    static func matchesPerMonth(for player: Player, in all: [Match], months: Int = 6) -> [MonthPoint] {
        let cal = Calendar.current
        let now = Date.now
        guard let startMonth = cal.date(from: cal.dateComponents([.year, .month], from: now)) else {
            return []
        }
        var buckets: [Date: Int] = [:]
        var axis: [Date] = []
        for offset in stride(from: months - 1, through: 0, by: -1) {
            if let d = cal.date(byAdding: .month, value: -offset, to: startMonth) {
                axis.append(d)
                buckets[d] = 0
            }
        }
        for m in matches(for: player, in: all) {
            let comps = cal.dateComponents([.year, .month], from: m.date)
            if let bucket = cal.date(from: comps), buckets[bucket] != nil {
                buckets[bucket, default: 0] += 1
            }
        }
        return axis.map { MonthPoint(date: $0, count: buckets[$0] ?? 0) }
    }

    struct RatingPoint: Identifiable {
        let index: Int
        let date: Date
        let rating: Double
        var id: Int { index }
    }

    /// Reconstructs `player`'s rating history by replaying completed matches in
    /// chronological order through `RatingEngine`. Other players' ratings are
    /// approximated as fixed at their current values, which is enough for a clear,
    /// transparent trend line. The series starts at the default 3.0 baseline.
    static func ratingHistory(for player: Player, in all: [Match]) -> [RatingPoint] {
        let chrono = all
            .filter { $0.isComplete && involves(player, $0) }
            .sorted { $0.date < $1.date }
        guard !chrono.isEmpty else { return [] }

        var rating = 3.0
        var points: [RatingPoint] = [
            RatingPoint(index: 0, date: chrono[0].date, rating: rating)
        ]
        for (i, m) in chrono.enumerated() {
            let onMine = isOnMySide(player, m)
            let myRatings = (onMine ? m.mySide : m.oppSide)
                .map { $0.persistentModelID == player.persistentModelID ? rating : $0.rating }
            let oppRatings = (onMine ? m.oppSide : m.mySide).map(\.rating)
            rating = RatingEngine.updatedRating(current: rating,
                                                myRatings: myRatings,
                                                oppRatings: oppRatings,
                                                didWin: didWin(player, m))
            points.append(RatingPoint(index: i + 1, date: m.date, rating: rating))
        }
        return points
    }
}

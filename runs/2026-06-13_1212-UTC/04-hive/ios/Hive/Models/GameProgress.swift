import Foundation
import SwiftData

/// Persistent progress for one puzzle on one day. `dayKey` is "" for practice
/// games and "yyyy-MM-dd" for a dated daily puzzle, so a daily and a practice
/// run of the same letters never collide. Found words persist so any puzzle
/// resumes exactly where it was left after relaunch.
@Model
final class GameProgress {
    var puzzleID: Int
    var dayKey: String
    var foundWords: [String]
    var startedAt: Date
    var completedGenius: Bool

    init(puzzleID: Int, dayKey: String, foundWords: [String] = [],
         startedAt: Date = .now, completedGenius: Bool = false) {
        self.puzzleID = puzzleID
        self.dayKey = dayKey
        self.foundWords = foundWords
        self.startedAt = startedAt
        self.completedGenius = completedGenius
    }

    /// True for the once-a-day dated puzzle (vs an unlimited practice run).
    var isDaily: Bool { !dayKey.isEmpty }
}

/// Aggregate stats computed over all saved progress records.
struct GameStats {
    let gamesPlayed: Int
    let totalPangrams: Int
    let geniusCount: Int
    let bestRankName: String
    let currentStreak: Int
    let totalFoundWords: Int
    /// Rank name -> number of games that finished at that rank.
    let rankDistribution: [(name: String, count: Int)]

    static func from(_ allRecords: [GameProgress], bank: [Puzzle]) -> GameStats {
        let byID = Dictionary(uniqueKeysWithValues: bank.map { ($0.id, $0) })
        // Only count games where the player actually found at least one word, so
        // a board merely opened (which creates an empty record) is not a "game".
        let records = allRecords.filter { !$0.foundWords.isEmpty }

        var pangrams = 0
        var genius = 0
        var foundTotal = 0
        var bestFraction = -1.0
        var bestRank = ScoreEngine.ranks.first?.name ?? "Beginner"
        var distCounts: [String: Int] = [:]

        for rec in records {
            foundTotal += rec.foundWords.count
            guard let puzzle = byID[rec.puzzleID] else { continue }
            pangrams += rec.foundWords.filter { puzzle.isPangram($0) }.count
            let max = ScoreEngine.maxScore(puzzle)
            let score = ScoreEngine.currentScore(found: rec.foundWords, in: puzzle)
            if ScoreEngine.isGenius(score: score, max: max) { genius += 1 }
            let rank = ScoreEngine.rank(for: score, max: max)
            distCounts[rank.name, default: 0] += 1
            let frac = max > 0 ? Double(score) / Double(max) : 0
            if frac > bestFraction { bestFraction = frac; bestRank = rank.name }
        }

        let distribution = ScoreEngine.ranks.map { (name: $0.name, count: distCounts[$0.name] ?? 0) }

        // Daily streak: consecutive days (ending today or yesterday) with a daily game.
        let cal = Calendar.current
        let dailyDays: Set<String> = Set(records.filter { $0.isDaily }.map { $0.dayKey })
        var streak = 0
        var cursor = Date.now
        // Allow today to be missing without breaking the streak.
        if !dailyDays.contains(DailyEngine.dayKey(for: cursor)) {
            cursor = cal.date(byAdding: .day, value: -1, to: cursor) ?? cursor
        }
        while dailyDays.contains(DailyEngine.dayKey(for: cursor)) {
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }

        return GameStats(
            gamesPlayed: records.count,
            totalPangrams: pangrams,
            geniusCount: genius,
            bestRankName: records.isEmpty ? "—" : bestRank,
            currentStreak: streak,
            totalFoundWords: foundTotal,
            rankDistribution: distribution)
    }
}

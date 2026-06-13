import Foundation
import SwiftData

@Model
final class GameRecord {
    var dayKey: String        // "" for practice games
    var date: Date
    var answer: String
    var guesses: [String]
    var won: Bool
    var hardMode: Bool

    init(dayKey: String, date: Date = .now, answer: String, guesses: [String], won: Bool, hardMode: Bool) {
        self.dayKey = dayKey
        self.date = date
        self.answer = answer
        self.guesses = guesses
        self.won = won
        self.hardMode = hardMode
    }

    var attempts: Int { guesses.count }
    var isDaily: Bool { !dayKey.isEmpty }
}

/// Win-rate, streaks, and the guess distribution from completed daily games.
struct StatsSummary {
    let played: Int
    let wins: Int
    let currentStreak: Int
    let maxStreak: Int
    let distribution: [Int]   // index 0 = solved in 1, ... index 5 = solved in 6

    var winPercent: Int { played == 0 ? 0 : Int((Double(wins) / Double(played) * 100).rounded()) }

    static func from(_ records: [GameRecord]) -> StatsSummary {
        let daily = records.filter { $0.isDaily }
        let wins = daily.filter { $0.won }
        var dist = [Int](repeating: 0, count: WordGame.maxRows)
        for r in wins where (1...WordGame.maxRows).contains(r.attempts) {
            dist[r.attempts - 1] += 1
        }

        // Streaks over consecutive calendar days where the daily was won.
        let cal = Calendar.current
        let wonDays = Set(wins.compactMap { WordGame.date(fromDayKey: $0.dayKey).map { cal.startOfDay(for: $0) } })
        let sortedDays = wonDays.sorted()

        var maxStreak = 0, run = 0
        var prev: Date?
        for day in sortedDays {
            if let p = prev, let diff = cal.dateComponents([.day], from: p, to: day).day, diff == 1 {
                run += 1
            } else { run = 1 }
            maxStreak = max(maxStreak, run)
            prev = day
        }

        var current = 0
        if let last = sortedDays.last {
            let today = cal.startOfDay(for: .now)
            let gap = cal.dateComponents([.day], from: last, to: today).day ?? 99
            if gap <= 1 {
                current = 1
                var cursor = last
                while let p = cal.date(byAdding: .day, value: -1, to: cursor), wonDays.contains(p) {
                    current += 1; cursor = p
                }
            }
        }

        return StatsSummary(played: daily.count, wins: wins.count,
                            currentStreak: current, maxStreak: maxStreak, distribution: dist)
    }
}

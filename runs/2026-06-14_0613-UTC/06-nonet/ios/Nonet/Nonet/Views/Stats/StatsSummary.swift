import Foundation

/// A Sendable snapshot of a GameRecord, so stats can be computed off the main actor
/// without touching SwiftData model objects from a background context.
struct RecordLite: Sendable {
    let difficultyRaw: Int
    let timeSec: Int
    let won: Bool
    let dateKey: String
    let date: Date
}

/// Per-difficulty aggregate (Identifiable for Swift Charts series).
struct DifficultyStat: Identifiable, Sendable {
    let id: Int
    let difficulty: Difficulty
    let played: Int
    let won: Int
    let bestTime: Int?
    let avgTime: Int?

    var winRate: Double { played > 0 ? Double(won) / Double(played) : 0 }
}

/// One day in the solved-days heatmap (Identifiable for ForEach).
struct HeatDay: Identifiable, Sendable {
    let id: Int
    let label: String
    let count: Int
    var solved: Bool { count > 0 }
    /// Opacity intensity 0.3...1 based on count.
    var intensity: Double {
        switch count {
        case 0: return 0
        case 1: return 0.45
        case 2: return 0.7
        default: return 1.0
        }
    }
}

/// Fully computed stats. Built off the main thread.
struct StatsSummary: Sendable {
    let totalWon: Int
    let currentStreak: Int
    let longestStreak: Int
    let byDifficulty: [DifficultyStat]
    let heatmap: [HeatDay]

    static func build(from records: [RecordLite], currentStreak: Int, longestStreak: Int) -> StatsSummary {
        var played = [Int: Int]()
        var won = [Int: Int]()
        var times = [Int: [Int]]()

        for r in records {
            played[r.difficultyRaw, default: 0] += 1
            if r.won {
                won[r.difficultyRaw, default: 0] += 1
                times[r.difficultyRaw, default: []].append(r.timeSec)
            }
        }

        var stats = [DifficultyStat]()
        for diff in Difficulty.allCases {
            let raw = diff.rawValue
            let t = times[raw] ?? []
            let best = t.min()
            let avg = t.isEmpty ? nil : t.reduce(0, +) / t.count
            stats.append(DifficultyStat(id: raw, difficulty: diff,
                                        played: played[raw] ?? 0,
                                        won: won[raw] ?? 0,
                                        bestTime: best, avgTime: avg))
        }

        // Solved-days heatmap for the last 35 days.
        var byDay = [String: Int]()
        for r in records where r.won {
            let key = r.dateKey.isEmpty ? DailySeed.dateKey(for: r.date) : r.dateKey
            byDay[key, default: 0] += 1
        }
        let cal = Calendar.current
        var heat = [HeatDay]()
        let today = Date()
        for offset in stride(from: 34, through: 0, by: -1) {
            if let day = cal.date(byAdding: .day, value: -offset, to: today) {
                let key = DailySeed.dateKey(for: day, calendar: cal)
                let f = DateFormatter(); f.dateStyle = .medium
                heat.append(HeatDay(id: 34 - offset, label: f.string(from: day),
                                    count: byDay[key] ?? 0))
            } else {
                heat.append(HeatDay(id: 34 - offset, label: "", count: 0))
            }
        }

        let totalWon = records.reduce(0) { $0 + ($1.won ? 1 : 0) }
        return StatsSummary(totalWon: totalWon, currentStreak: currentStreak,
                            longestStreak: longestStreak, byDifficulty: stats, heatmap: heat)
    }
}

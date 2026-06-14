import Foundation

/// Aggregated statistics computed from game and puzzle records.
struct StatsResult {
    var gamesPlayed = 0
    var wins = 0
    var losses = 0
    var draws = 0

    var puzzlesAttempted = 0
    var puzzlesSolved = 0
    var currentStreak = 0
    var bestStreak = 0

    /// Daily puzzle solved counts over recent days, oldest→newest.
    var solvedOverTime: [DayCount] = []
    /// Per-theme solved vs attempted.
    var themeBars: [ThemeStat] = []

    var isEmpty: Bool { gamesPlayed == 0 && puzzlesAttempted == 0 }

    var winRate: Double {
        gamesPlayed > 0 ? Double(wins) / Double(gamesPlayed) : 0
    }

    var puzzleAccuracy: Double {
        puzzlesAttempted > 0 ? Double(puzzlesSolved) / Double(puzzlesAttempted) : 0
    }

    struct DayCount: Identifiable {
        let id: Date
        let date: Date
        let solved: Int
    }

    struct ThemeStat: Identifiable {
        let id: String
        let theme: String
        let solved: Int
        let attempted: Int
    }
}

enum StatsEngine {
    /// Compute aggregate stats from raw records.
    static func compute(games: [GameRecord], puzzles: [PuzzleResult]) -> StatsResult {
        var r = StatsResult()

        r.gamesPlayed = games.count
        for g in games {
            switch g.result {
            case .win: r.wins += 1
            case .loss: r.losses += 1
            case .draw, .inProgress: r.draws += 1
            }
        }

        // Puzzle attempts are deduped by puzzle id (best outcome counts).
        var bestByPuzzle: [Int: Bool] = [:]
        for p in puzzles {
            let prev = bestByPuzzle[p.puzzleID] ?? false
            bestByPuzzle[p.puzzleID] = prev || p.solved
        }
        r.puzzlesAttempted = bestByPuzzle.count
        r.puzzlesSolved = bestByPuzzle.values.filter { $0 }.count

        // Streaks: walk solved puzzle-attempts in chronological order.
        let chrono = puzzles.sorted { $0.date < $1.date }
        var cur = 0
        var best = 0
        for p in chrono {
            if p.solved {
                cur += 1
                best = max(best, cur)
            } else {
                cur = 0
            }
        }
        r.currentStreak = cur
        r.bestStreak = best

        // Solved-over-time: bucket solved attempts by calendar day for the last 14 days.
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        var dayMap: [Date: Int] = [:]
        for p in puzzles where p.solved {
            let day = cal.startOfDay(for: p.date)
            dayMap[day, default: 0] += 1
        }
        var days: [StatsResult.DayCount] = []
        for offset in stride(from: 13, through: 0, by: -1) {
            if let day = cal.date(byAdding: .day, value: -offset, to: today) {
                days.append(.init(id: day, date: day, solved: dayMap[day] ?? 0))
            }
        }
        r.solvedOverTime = days

        // Per-theme bars.
        var themeSolved: [String: Int] = [:]
        var themeAttempted: [String: Int] = [:]
        for (pid, solved) in bestByPuzzle {
            guard let pz = PuzzleBank.puzzle(id: pid) else { continue }
            let key = pz.theme.rawValue
            themeAttempted[key, default: 0] += 1
            if solved { themeSolved[key, default: 0] += 1 }
        }
        r.themeBars = themeAttempted.keys.sorted().map { key in
            .init(id: key, theme: key, solved: themeSolved[key] ?? 0, attempted: themeAttempted[key] ?? 0)
        }

        return r
    }
}

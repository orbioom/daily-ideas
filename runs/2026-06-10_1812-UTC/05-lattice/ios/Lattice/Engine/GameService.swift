import Foundation
import SwiftData

/// Helpers that create games and record results against SwiftData.
enum GameService {

    /// Generate a fresh non-daily game, replacing any existing unfinished one.
    static func newGame(difficulty: Difficulty, context: ModelContext, existing: [SavedGame]) -> SavedGame {
        for game in existing where !game.isDaily && !game.isComplete {
            context.delete(game)
        }
        let seed = UInt64(Date.now.timeIntervalSince1970 * 1000) ^ UInt64(bitPattern: Int64(Int.random(in: 0...Int.max)))
        let puzzle = SudokuEngine.generate(difficulty: difficulty, seed: seed)
        let game = SavedGame(difficulty: difficulty, givens: puzzle.givens, solution: puzzle.solution)
        context.insert(game)
        try? context.save()
        return game
    }

    /// The deterministic daily puzzle for a given day, created on demand.
    static func dailyGame(for date: Date, difficulty: Difficulty = .medium,
                          context: ModelContext, existing: [SavedGame]) -> SavedGame {
        let key = SudokuEngine.dayKey(date)
        if let game = existing.first(where: { $0.isDaily && $0.dailyKey == key }) {
            return game
        }
        let seed = UInt64(bitPattern: Int64(key)) &* 0x9E3779B97F4A7C15
        let puzzle = SudokuEngine.generate(difficulty: difficulty, seed: seed)
        let game = SavedGame(difficulty: difficulty, givens: puzzle.givens,
                             solution: puzzle.solution, isDaily: true, dailyKey: key)
        context.insert(game)
        try? context.save()
        return game
    }

    /// Record a loss (e.g. ran out of mistakes): counts toward played, not won.
    static func recordLoss(_ game: SavedGame, context: ModelContext, allStats: [GameStats]) {
        let stats = self.stats(for: game.difficulty, context: context, all: allStats)
        stats.played += 1
        try? context.save()
    }

    static func stats(for difficulty: Difficulty, context: ModelContext, all: [GameStats]) -> GameStats {
        if let existing = all.first(where: { $0.difficultyRaw == difficulty.rawValue }) {
            return existing
        }
        let s = GameStats(difficulty: difficulty)
        context.insert(s)
        return s
    }

    /// Record a game's outcome into stats and daily results.
    static func recordCompletion(_ game: SavedGame, context: ModelContext,
                                 allStats: [GameStats], allDaily: [DailyResult]) {
        let stats = self.stats(for: game.difficulty, context: context, all: allStats)
        stats.played += 1
        stats.won += 1
        stats.totalWinTime += game.elapsed
        if stats.bestTime == 0 || game.elapsed < stats.bestTime {
            stats.bestTime = game.elapsed
        }
        if game.isDaily {
            if let daily = allDaily.first(where: { $0.dayKey == game.dailyKey }) {
                daily.completed = true
                daily.timeSeconds = game.elapsed
            } else {
                let d = DailyResult(dayKey: game.dailyKey, date: game.createdAt)
                d.completed = true
                d.timeSeconds = game.elapsed
                context.insert(d)
            }
        }
        try? context.save()
    }
}

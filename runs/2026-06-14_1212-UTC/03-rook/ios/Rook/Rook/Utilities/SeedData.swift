import Foundation
import SwiftData

/// Seeds a realistic batch of sample records so the Stats screen is lively at first run.
enum SeedData {
    /// Insert ~60 game records and ~70 puzzle results spread over the last few weeks.
    static func load(context: ModelContext, existingGames: Int, existingPuzzles: Int) {
        let cal = Calendar.current
        let now = Date()
        var rng = SeededGenerator(seed: 42)

        // --- Games over the last 30 days ---
        let levels = [AILevel.easy, .medium, .hard]
        for i in 0..<60 {
            let dayOffset = Int(rng.next() % 30)
            let date = cal.date(byAdding: .day, value: -dayOffset, to: now) ?? now
            let roll = rng.next() % 100
            let result: GameResultKind = roll < 52 ? .win : (roll < 80 ? .loss : .draw)
            let level = levels[Int(rng.next() % 3)]
            let record = GameRecord(date: date,
                                    result: result,
                                    vsComputer: true,
                                    computerLevel: level.rawValue,
                                    moveCount: 20 + Int(rng.next() % 50))
            context.insert(record)
            _ = i
        }

        // --- Puzzle results over the last 21 days, biased toward solving ---
        let ids = PuzzleBank.all.map { $0.id }
        for _ in 0..<72 {
            let dayOffset = Int(rng.next() % 21)
            let date = cal.date(byAdding: .day, value: -dayOffset, to: now) ?? now
            let id = ids[Int(rng.next() % UInt64(max(1, ids.count)))]
            let solved = (rng.next() % 100) < 74
            let hints = solved ? Int(rng.next() % 2) : Int(rng.next() % 3)
            let attempts = solved ? 1 + Int(rng.next() % 2) : 1 + Int(rng.next() % 3)
            let result = PuzzleResult(puzzleID: id,
                                      date: date,
                                      solved: solved,
                                      hintsUsed: hints,
                                      attempts: attempts)
            context.insert(result)
        }
    }
}

/// A tiny deterministic PRNG (xorshift) so sample data is stable across runs.
private struct SeededGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed == 0 ? 0x9E3779B97F4A7C15 : seed }
    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}

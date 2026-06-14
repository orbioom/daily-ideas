import Foundation
import SwiftData

/// Seeds a realistic solving history (progress + daily results) so Stats and
/// Archive look alive immediately. Idempotent behind the "didSeed" flag.
enum SeedData {

    /// Build a believable back-history: a streak of recent daily solves plus a
    /// handful of archive puzzles in progress / completed.
    static func seedIfNeeded(context: ModelContext, didSeed: inout Bool) {
        guard !didSeed else { return }
        seed(context: context)
        didSeed = true
    }

    /// Force a reseed (used by the Settings "Load sample data" action).
    static func reseed(context: ModelContext) {
        clearAll(context: context)
        seed(context: context)
    }

    private static func seed(context: ModelContext) {
        let bank = PuzzleBank.all
        guard !bank.isEmpty else { return }

        // 1. A run of daily results for the past ~40 days (with a couple of gaps
        //    so the streak math is exercised). Times trend down as "skill" grows.
        let today = Date()
        var rng = SeededRNG(seed: 42)
        for offset in stride(from: 40, through: 1, by: -1) {
            // Two intentional skipped days to break the streak.
            if offset == 17 || offset == 18 { continue }
            let dayNumber = max(0, DateKey.dayNumber(for: today) - offset)
            let puzzle = bank[dayNumber % bank.count]
            let key = DateKey.key(offsetDays: -offset, from: today)
            let base = 120 - min(offset, 40)            // gets faster over time
            let jitter = Int(rng.next() % 50)
            let secs = max(35, base + jitter - 25)
            let usedCheck = rng.next() % 5 == 0
            let usedReveal = rng.next() % 11 == 0
            let r = DailyResult(dateKey: key,
                                puzzleID: puzzle.id,
                                solved: true,
                                elapsedSeconds: secs,
                                usedCheck: usedCheck,
                                usedReveal: usedReveal,
                                difficultyRaw: puzzle.difficulty.rawValue,
                                recordedAt: shifted(today, days: -offset))
            context.insert(r)
        }

        // 2. A scatter of archive completions (full solves) for variety in stats.
        for i in 0..<min(14, bank.count) {
            let puzzle = bank[(i * 3 + 1) % bank.count]
            guard let engine = puzzle.makeEngine() else { continue }
            let entered = solvedEntered(engine: engine)
            let secs = 60 + Int(rng.next() % 130)
            let p = PuzzleProgress(puzzleID: puzzle.id,
                                   enteredLetters: entered,
                                   revealedMask: blankMask(engine),
                                   checkedMask: blankMask(engine),
                                   completed: true,
                                   elapsedSeconds: secs,
                                   solvedAt: shifted(today, days: -(i + 1)),
                                   lastPlayedAt: shifted(today, days: -(i + 1)))
            mergeProgress(p, context: context)
        }

        // 3. A couple of in-progress puzzles so "Resume" has something to show.
        for i in 0..<min(3, bank.count) {
            let puzzle = bank[(i * 5 + 2) % bank.count]
            guard let engine = puzzle.makeEngine() else { continue }
            let entered = partialEntered(engine: engine, fillRatio: 0.4)
            let p = PuzzleProgress(puzzleID: puzzle.id,
                                   enteredLetters: entered,
                                   revealedMask: blankMask(engine),
                                   checkedMask: blankMask(engine),
                                   completed: false,
                                   elapsedSeconds: 40 + i * 15,
                                   solvedAt: nil,
                                   lastPlayedAt: shifted(today, days: 0))
            mergeProgress(p, context: context)
        }

        try? context.save()
    }

    /// Insert progress unless one already exists for that puzzle.
    private static func mergeProgress(_ p: PuzzleProgress, context: ModelContext) {
        let id = p.puzzleID
        let descriptor = FetchDescriptor<PuzzleProgress>(predicate: #Predicate { $0.puzzleID == id })
        if (try? context.fetch(descriptor))?.first == nil {
            context.insert(p)
        }
    }

    /// Remove all solving history.
    static func clearAll(context: ModelContext) {
        if let progress = try? context.fetch(FetchDescriptor<PuzzleProgress>()) {
            for p in progress { context.delete(p) }
        }
        if let results = try? context.fetch(FetchDescriptor<DailyResult>()) {
            for r in results { context.delete(r) }
        }
        try? context.save()
    }

    // MARK: Grid encoding helpers

    private static func solvedEntered(engine: CrosswordEngine) -> String {
        var out = ""
        for r in 0..<engine.rows {
            for c in 0..<engine.cols {
                let info = engine.cellInfo[r][c]
                if info.isBlock { out.append("#") }
                else { out.append(engine.solution[r][c]) }
            }
        }
        return out
    }

    private static func partialEntered(engine: CrosswordEngine, fillRatio: Double) -> String {
        var rng = SeededRNG(seed: 7)
        var out = ""
        for r in 0..<engine.rows {
            for c in 0..<engine.cols {
                let info = engine.cellInfo[r][c]
                if info.isBlock { out.append("#") }
                else {
                    let roll = Double(rng.next() % 100) / 100.0
                    out.append(roll < fillRatio ? engine.solution[r][c] : ".")
                }
            }
        }
        return out
    }

    private static func blankMask(_ engine: CrosswordEngine) -> String {
        var out = ""
        for r in 0..<engine.rows {
            for c in 0..<engine.cols {
                out.append(engine.cellInfo[r][c].isBlock ? "#" : "0")
            }
        }
        return out
    }

    private static func shifted(_ date: Date, days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: date) ?? date
    }
}

/// Tiny deterministic RNG so seeded data is stable across runs.
private struct SeededRNG {
    private var state: UInt64
    init(seed: UInt64) { state = seed &+ 0x9E3779B97F4A7C15 }
    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}

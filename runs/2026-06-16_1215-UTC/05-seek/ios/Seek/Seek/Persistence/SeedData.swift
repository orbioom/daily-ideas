import Foundation
import SwiftData

/// Seeds a handful of completed puzzles and daily results on first launch so the
/// Stats and Daily screens have realistic content. Guarded to run exactly once.
@MainActor
enum SeedData {
    private static let seededFlagKey = "didSeedSampleData_v1"

    static func seedIfNeeded(context: ModelContext) {
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: seededFlagKey) { return }

        // Double-guard: if data already exists, don't duplicate.
        let existing = (try? context.fetch(FetchDescriptor<PuzzleProgress>())) ?? []
        if !existing.isEmpty {
            defaults.set(true, forKey: seededFlagKey)
            return
        }

        seedPuzzles(context: context)
        seedDailies(context: context)

        do {
            try context.save()
            defaults.set(true, forKey: seededFlagKey)
        } catch {
            // If saving fails we simply leave the flag unset so seeding can retry next launch.
        }
    }

    private static func seedPuzzles(context: ModelContext) {
        let calendar = Calendar.current
        let now = Date()

        // (packID, index, difficulty, daysAgo, timeSec)
        let samples: [(String, Int, Difficulty, Int, Int)] = [
            ("animals", 0, .easy, 9, 96),
            ("animals", 1, .easy, 8, 84),
            ("food", 0, .easy, 7, 110),
            ("food", 1, .medium, 6, 187),
            ("house", 0, .easy, 5, 72),
            ("house", 1, .medium, 4, 165),
            ("animals", 2, .medium, 3, 152),
            ("food", 2, .hard, 2, 268),
            ("house", 2, .hard, 1, 241)
        ]

        for sample in samples {
            let (packID, index, difficulty, daysAgo, timeSec) = sample
            guard let pack = WordPackLibrary.pack(id: packID) else { continue }
            let puzzle = Puzzle(packID: packID, index: index, difficulty: difficulty)
            let board = WordSearchGenerator.generate(
                words: pack.words,
                size: difficulty.gridSize,
                directions: difficulty.directions(allowDiagonals: true, allowReverse: true),
                targetCount: difficulty.targetWordCount,
                seed: puzzle.seed
            )
            let completedDate = calendar.date(byAdding: .day, value: -daysAgo, to: now) ?? now
            let progress = PuzzleProgress(
                puzzleKey: puzzle.key,
                packName: pack.name,
                difficultyRaw: difficulty.rawValue,
                seed: Int(bitPattern: UInt(truncatingIfNeeded: puzzle.seed)),
                gridSize: board.size,
                foundWords: board.words,
                isComplete: true,
                elapsedSec: timeSec,
                bestTimeSec: timeSec,
                startedDate: completedDate,
                completedDate: completedDate
            )
            context.insert(progress)
        }
    }

    private static func seedDailies(context: ModelContext) {
        let calendar = Calendar.current
        let now = Date()
        // Seed a short streak of recent daily completions.
        let dailySamples: [(Int, Int, Int, Int)] = [
            // daysAgo, timeSec, foundCount, total
            (4, 142, 10, 10),
            (3, 130, 10, 10),
            (2, 168, 10, 10),
            (1, 121, 10, 10)
        ]
        for sample in dailySamples {
            let (daysAgo, timeSec, found, total) = sample
            guard let day = calendar.date(byAdding: .day, value: -daysAgo, to: now) else { continue }
            let key = Formatters.dayKey(day)
            let seed = DailyPuzzle.seed(for: key)
            let result = DailyResult(
                dateKey: key,
                seed: Int(bitPattern: UInt(truncatingIfNeeded: seed)),
                timeSec: timeSec,
                foundCount: found,
                total: total,
                completed: true
            )
            context.insert(result)
        }
    }
}

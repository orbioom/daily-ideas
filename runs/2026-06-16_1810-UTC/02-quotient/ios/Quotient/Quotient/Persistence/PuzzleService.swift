import Foundation

/// Bridges the pure engine to the async UI. Generation runs off the main actor
/// so the UI can show a brief "generating" state without blocking.
struct PuzzleService {

    /// Generates a puzzle for the given difficulty and seed. Marked `async` and
    /// run on a background task so a heavy 7×7 generation never stalls the UI.
    static func generate(difficulty: Difficulty, seed: UInt64) async -> Puzzle {
        await Task.detached(priority: .userInitiated) {
            PuzzleGenerator(difficulty: difficulty).generate(seed: seed)
        }.value
    }

    /// The deterministic daily puzzle for a date key.
    static func daily(forDateKey key: String) async -> Puzzle {
        let difficulty = Difficulty.daily(for: DateKey.date(from: key) ?? Date())
        let seed = SplitMix64.seed(forDateKey: key)
        return await generate(difficulty: difficulty, seed: seed)
    }

    // MARK: Encoding helpers

    static func encode(_ puzzle: Puzzle) -> Data {
        (try? JSONEncoder().encode(puzzle)) ?? Data()
    }

    static func encode(_ states: [CellState]) -> Data {
        (try? JSONEncoder().encode(states)) ?? Data()
    }
}

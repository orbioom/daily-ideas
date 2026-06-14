import Foundation

/// A generated puzzle: its givens, its unique solution, and the difficulty grade.
struct Puzzle {
    let givens: [Int]    // length 81, 0 = empty
    let solution: [Int]  // length 81, the unique completion
    let difficulty: Difficulty
}

/// Generates Sudoku puzzles with a unique solution graded to a target difficulty.
///
/// Pipeline:
///  1. Build a full valid solution via randomized backtracking (seeded RNG).
///  2. Dig holes symmetrically while `solutionCount == 1` is preserved and the logical
///     solver's hardest-required technique still matches the target difficulty.
///  3. Cap both attempts and wall-clock TIME. If the target can't be met within budget,
///     return the best valid unique puzzle found. If even that fails, fall back to the
///     verified PuzzleBank so the app never hangs.
enum SudokuGenerator {

    /// Generate a puzzle. `seed` (when non-nil) makes generation deterministic — used for
    /// the daily puzzle so everyone gets the same board. `timeBudget` is wall-clock seconds.
    static func generate(difficulty: Difficulty, seed: UInt64? = nil, timeBudget: TimeInterval = 2.5) -> Puzzle {
        var rng = SplitMix64(seed: seed ?? UInt64.random(in: 1...UInt64.max))
        let deadline = Date().addingTimeInterval(timeBudget)

        guard let solution = fullSolution(using: &rng) else {
            return PuzzleBank.fallback(for: difficulty, using: &rng)
        }

        var best: [Int]? = nil
        var bestHoles = -1
        var bestMatches = false   // whether the current `best` hits the target grade exactly
        let target = difficulty.maxTechnique

        // A few independent dig attempts (each from the full solution) within budget.
        var attempt = 0
        while attempt < 12 && Date() < deadline {
            attempt += 1
            let dug = dig(from: solution, target: target, targetHoles: difficulty.targetHoles,
                          deadline: deadline, using: &rng)
            guard dug.unique else { continue }
            let holes = dug.givens.reduce(0) { $0 + ($1 == 0 ? 1 : 0) }
            // Preference order: a target-matching puzzle always beats a non-matching one;
            // among equals, prefer more holes (harder / cleaner).
            let better: Bool
            if dug.matchesTarget != bestMatches {
                better = dug.matchesTarget   // matching wins over non-matching
            } else {
                better = holes > bestHoles
            }
            if best == nil || better {
                best = dug.givens
                bestHoles = holes
                bestMatches = dug.matchesTarget
            }
        }

        if let givens = best, SudokuSolver.solutionCount(givens, maxToFind: 2) == 1 {
            return Puzzle(givens: givens, solution: solution, difficulty: difficulty)
        }
        // Couldn't build a graded unique puzzle in budget — use a verified fallback.
        return PuzzleBank.fallback(for: difficulty, using: &rng)
    }

    // MARK: - Full solution via randomized backtracking

    private static func fullSolution(using rng: inout SplitMix64) -> [Int]? {
        var grid = [Int](repeating: 0, count: 81)
        if fill(&grid, using: &rng) { return grid }
        return nil
    }

    private static func fill(_ grid: inout [Int], using rng: inout SplitMix64) -> Bool {
        // Find first empty cell (deterministic order; randomness comes from digit shuffle).
        var index = -1
        for i in 0..<81 where grid[i] == 0 { index = i; break }
        if index == -1 { return true }
        var digits = Array(1...9)
        shuffle(&digits, using: &rng)
        for d in digits where SudokuSolver.isValidPlacement(grid, index: index, value: d) {
            grid[index] = d
            if fill(&grid, using: &rng) { return true }
            grid[index] = 0
        }
        return false
    }

    /// Fisher-Yates shuffle using the seeded RNG (so the daily is reproducible).
    private static func shuffle<T>(_ array: inout [T], using rng: inout SplitMix64) {
        guard array.count > 1 else { return }
        var i = array.count - 1
        while i > 0 {
            let j = Int(rng.next() % UInt64(i + 1))
            let safeJ = (j >= 0 && j <= i) ? j : 0
            array.swapAt(i, safeJ)
            i -= 1
        }
    }

    // MARK: - Symmetric digging

    private struct DigResult {
        let givens: [Int]
        let unique: Bool
        let matchesTarget: Bool
    }

    /// Removes cells in symmetric pairs (180° rotational) while keeping a unique solution
    /// and a grade that does not exceed the target. Stops at the deadline or when no more
    /// safe removals remain. Then verifies the final grade equals the target exactly.
    private static func dig(from solution: [Int], target: SolveTechnique, targetHoles: Int,
                            deadline: Date, using rng: inout SplitMix64) -> DigResult {
        var grid = solution
        var order = Array(0..<81)
        shuffle(&order, using: &rng)

        var holes = 0
        for index in order {
            if Date() >= deadline { break }
            if holes >= targetHoles { break }
            guard index >= 0, index < 81 else { continue }
            if grid[index] == 0 { continue }
            let mirror = 80 - index // 180° rotational partner

            let savedA = grid[index]
            let savedB = (mirror >= 0 && mirror < 81) ? grid[mirror] : 0

            grid[index] = 0
            var removed = 1
            if mirror != index, mirror >= 0, mirror < 81, grid[mirror] != 0 {
                grid[mirror] = 0
                removed = 2
            }

            // Must remain unique.
            if SudokuSolver.solutionCount(grid, maxToFind: 2) != 1 {
                grid[index] = savedA
                if removed == 2, mirror >= 0, mirror < 81 { grid[mirror] = savedB }
                continue
            }
            // Must not exceed the target technique (too hard). Easier is OK while digging;
            // a final exact-grade check is applied below.
            let g = SudokuSolver.grade(grid)
            if !g.solvable || g.hardest > target {
                grid[index] = savedA
                if removed == 2, mirror >= 0, mirror < 81 { grid[mirror] = savedB }
                continue
            }
            holes += removed
        }

        let finalGrade = SudokuSolver.grade(grid)
        let unique = SudokuSolver.solutionCount(grid, maxToFind: 2) == 1
        // Exact match: the puzzle genuinely requires the target technique (not easier),
        // except Expert which accepts the hardest the engine can reach.
        let matches: Bool
        if target == .pair {
            matches = unique && finalGrade.solvable && finalGrade.hardest >= .lockedCandidate
        } else {
            matches = unique && finalGrade.solvable && finalGrade.hardest == target
        }
        return DigResult(givens: grid, unique: unique, matchesTarget: matches)
    }
}

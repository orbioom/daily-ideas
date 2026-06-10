import Foundation

/// Deterministic SplitMix64 generator so the daily puzzle is identical for
/// everyone on a given day and stable across relaunches.
struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed == 0 ? 0x9E3779B97F4A7C15 : seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

/// Pure Sudoku logic: generation (with unique-solution guarantee), solving,
/// and conflict detection. Operates on 81-length Int arrays (0 = empty).
enum SudokuEngine {

    static func dayKey(_ date: Date, calendar: Calendar = .current) -> Int {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return (c.year ?? 2026) * 10_000 + (c.month ?? 1) * 100 + (c.day ?? 1)
    }

    // MARK: - Validity

    /// True if placing `value` at `index` violates no row/column/box rule.
    static func isSafe(_ board: [Int], index: Int, value: Int) -> Bool {
        let row = index / 9, col = index % 9
        for k in 0..<9 {
            if board[row * 9 + k] == value { return false }
            if board[k * 9 + col] == value { return false }
        }
        let boxRow = (row / 3) * 3, boxCol = (col / 3) * 3
        for r in 0..<3 {
            for c in 0..<3 {
                if board[(boxRow + r) * 9 + (boxCol + c)] == value { return false }
            }
        }
        return true
    }

    /// Indices in the same row, column, or box as `index` (peers).
    static func peers(of index: Int) -> [Int] {
        let row = index / 9, col = index % 9
        var set = Set<Int>()
        for k in 0..<9 {
            set.insert(row * 9 + k)
            set.insert(k * 9 + col)
        }
        let boxRow = (row / 3) * 3, boxCol = (col / 3) * 3
        for r in 0..<3 { for c in 0..<3 { set.insert((boxRow + r) * 9 + (boxCol + c)) } }
        set.remove(index)
        return Array(set)
    }

    /// Indices whose current value conflicts with a peer holding the same value.
    static func conflicts(in board: [Int]) -> Set<Int> {
        var result = Set<Int>()
        for i in 0..<81 where board[i] != 0 {
            for p in peers(of: i) where board[p] == board[i] {
                result.insert(i); result.insert(p)
            }
        }
        return result
    }

    // MARK: - Solving

    private static func firstEmptyMRV(_ board: [Int]) -> (index: Int, candidates: [Int])? {
        var best: (index: Int, candidates: [Int])?
        var bestCount = 10
        for i in 0..<81 where board[i] == 0 {
            var cands: [Int] = []
            for v in 1...9 where isSafe(board, index: i, value: v) { cands.append(v) }
            if cands.isEmpty { return (i, []) }   // dead end
            if cands.count < bestCount {
                best = (i, cands)
                bestCount = cands.count
                if bestCount == 1 { return best }
            }
        }
        return best
    }

    /// Counts solutions up to `limit` (used for uniqueness; pass 2).
    static func countSolutions(_ board: [Int], limit: Int = 2) -> Int {
        var work = board
        var count = 0
        func recurse() {
            if count >= limit { return }
            guard let (index, cands) = firstEmptyMRV(work) else {
                count += 1
                return
            }
            if cands.isEmpty { return }
            for v in cands {
                work[index] = v
                recurse()
                work[index] = 0
                if count >= limit { return }
            }
        }
        recurse()
        return count
    }

    /// Solve the board in place (returns a solution if one exists).
    static func solve(_ board: [Int]) -> [Int]? {
        var work = board
        func recurse() -> Bool {
            guard let (index, cands) = firstEmptyMRV(work) else { return true }
            if cands.isEmpty { return false }
            for v in cands {
                work[index] = v
                if recurse() { return true }
                work[index] = 0
            }
            return false
        }
        return recurse() ? work : nil
    }

    // MARK: - Generation

    /// Build a complete, valid, randomly filled solution grid.
    private static func fullSolution(using rng: inout SeededRNG) -> [Int] {
        var board = Array(repeating: 0, count: 81)
        func fill() -> Bool {
            guard let idx = (0..<81).first(where: { board[$0] == 0 }) else { return true }
            let values = Array(1...9).shuffled(using: &rng)
            for v in values {
                if isSafe(board, index: idx, value: v) {
                    board[idx] = v
                    if fill() { return true }
                    board[idx] = 0
                }
            }
            return false
        }
        _ = fill()
        return board
    }

    /// Generate a puzzle (givens, solution) for a difficulty.
    /// Removes cells while keeping the solution unique.
    static func generate(difficulty: Difficulty, seed: UInt64) -> (givens: [Int], solution: [Int]) {
        var rng = SeededRNG(seed: seed)
        let solution = fullSolution(using: &rng)
        var puzzle = solution
        let order = Array(0..<81).shuffled(using: &rng)
        var clues = 81
        let target = difficulty.clueTarget

        for index in order {
            if clues <= target { break }
            let backup = puzzle[index]
            if backup == 0 { continue }
            puzzle[index] = 0
            // Keep removal only if the solution stays unique.
            if countSolutions(puzzle, limit: 2) != 1 {
                puzzle[index] = backup
            } else {
                clues -= 1
            }
        }
        return (puzzle, solution)
    }
}

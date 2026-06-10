import Foundation

/// A complete Sudoku engine: generation with guaranteed-unique solutions,
/// a backtracking solver, a logical (human-technique) hint finder, and a
/// difficulty estimate. Pure value types, no dependencies.
enum SudokuEngine {

    // MARK: - Validation

    /// Whether placing `value` (1...9) at `index` (0...80) is legal given `grid`.
    static func isLegal(_ grid: [Int], index: Int, value: Int) -> Bool {
        let row = index / 9, col = index % 9
        for c in 0..<9 {
            if grid[row * 9 + c] == value { return false }
        }
        for r in 0..<9 {
            if grid[r * 9 + col] == value { return false }
        }
        let br = (row / 3) * 3, bc = (col / 3) * 3
        for r in br..<br+3 {
            for c in bc..<bc+3 {
                if grid[r * 9 + c] == value { return false }
            }
        }
        return true
    }

    // MARK: - Solver (backtracking, counts up to 2 solutions)

    /// Returns the number of solutions, capped at `cap`. Used for uniqueness.
    static func solutionCount(_ grid: [Int], cap: Int = 2) -> Int {
        var g = grid
        var count = 0
        func solve() {
            if count >= cap { return }
            guard let idx = bestEmpty(g) else { count += 1; return }
            for v in 1...9 where isLegal(g, index: idx, value: v) {
                g[idx] = v
                solve()
                g[idx] = 0
                if count >= cap { return }
            }
        }
        solve()
        return count
    }

    /// Solve in place, returning a completed grid if solvable.
    static func solve(_ grid: [Int]) -> [Int]? {
        var g = grid
        func go() -> Bool {
            guard let idx = bestEmpty(g) else { return true }
            for v in 1...9 where isLegal(g, index: idx, value: v) {
                g[idx] = v
                if go() { return true }
                g[idx] = 0
            }
            return false
        }
        return go() ? g : nil
    }

    /// Choose the empty cell with the fewest candidates (MRV heuristic) to keep
    /// backtracking fast.
    private static func bestEmpty(_ grid: [Int]) -> Int? {
        var best: Int? = nil
        var bestCount = 10
        for i in 0..<81 where grid[i] == 0 {
            var c = 0
            for v in 1...9 where isLegal(grid, index: i, value: v) { c += 1 }
            if c < bestCount { bestCount = c; best = i; if c <= 1 { break } }
        }
        return best
    }

    // MARK: - Generation

    /// A fully solved board via randomized backtracking.
    static func generateSolved(rng: inout SeededRNG) -> [Int] {
        var g = [Int](repeating: 0, count: 81)
        func fill() -> Bool {
            guard let idx = g.firstIndex(of: 0) else { return true }
            var vals = Array(1...9)
            vals.shuffle(using: &rng)
            for v in vals where isLegal(g, index: idx, value: v) {
                g[idx] = v
                if fill() { return true }
                g[idx] = 0
            }
            return false
        }
        _ = fill()
        return g
    }

    /// A puzzle (givens) and its unique solution for the given difficulty.
    static func generate(_ difficulty: SudokuDifficulty, seed: UInt64? = nil) -> (givens: [Int], solution: [Int]) {
        var rng = SeededRNG(seed: seed ?? UInt64.random(in: 0..<UInt64.max))
        let solution = generateSolved(rng: &rng)
        var puzzle = solution
        let targetClues = difficulty.targetClues
        var order = Array(0..<81)
        order.shuffle(using: &rng)

        var clues = 81
        for idx in order {
            if clues <= targetClues { break }
            let backup = puzzle[idx]
            puzzle[idx] = 0
            // Keep the removal only if the solution stays unique.
            if solutionCount(puzzle, cap: 2) != 1 {
                puzzle[idx] = backup
            } else {
                clues -= 1
            }
        }
        return (puzzle, solution)
    }

    // MARK: - Hints (human techniques)

    /// Find one logically deducible cell: a naked single (one candidate) or a
    /// hidden single (only cell in a unit that can hold a digit). Returns the
    /// cell index and value, or nil if none found by these techniques.
    static func logicalHint(_ grid: [Int]) -> (index: Int, value: Int)? {
        // Naked single
        for i in 0..<81 where grid[i] == 0 {
            var only = 0, count = 0
            for v in 1...9 where isLegal(grid, index: i, value: v) { only = v; count += 1 }
            if count == 1 { return (i, only) }
        }
        // Hidden single in rows, cols, boxes
        for unit in units {
            for v in 1...9 {
                let spots = unit.filter { grid[$0] == 0 && isLegal(grid, index: $0, value: v) }
                let alreadyPlaced = unit.contains { grid[$0] == v }
                if !alreadyPlaced && spots.count == 1 { return (spots[0], v) }
            }
        }
        return nil
    }

    /// The 27 units (9 rows, 9 cols, 9 boxes) as index lists.
    static let units: [[Int]] = {
        var u: [[Int]] = []
        for r in 0..<9 { u.append((0..<9).map { r * 9 + $0 }) }
        for c in 0..<9 { u.append((0..<9).map { $0 * 9 + c }) }
        for br in 0..<3 {
            for bc in 0..<3 {
                var box: [Int] = []
                for r in 0..<3 { for c in 0..<3 { box.append((br*3+r)*9 + (bc*3+c)) } }
                u.append(box)
            }
        }
        return u
    }()

    /// Candidate digits for a cell (for auto-notes).
    static func candidates(_ grid: [Int], index: Int) -> [Int] {
        guard grid[index] == 0 else { return [] }
        return (1...9).filter { isLegal(grid, index: index, value: $0) }
    }
}

/// A small, deterministic SplitMix64 RNG so daily puzzles are reproducible.
struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state = state &+ 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

import Foundation

/// A reproducible 64-bit RNG (SplitMix64). Seeding from a date makes the daily
/// challenge identical for everyone on the same calendar day.
struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        // Avoid an all-zero state which would degrade the stream.
        state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

/// The four swipe directions.
enum Direction: CaseIterable {
    case up, down, left, right
}

/// Result of attempting a move. Pure value type — no SwiftUI, fully testable.
struct MoveResult: Equatable {
    /// The grid after the move (unchanged if `moved` is false).
    var grid: [[Int]]
    /// Sum of all newly-formed merged tile values this move (the points gained).
    var gained: Int
    /// Whether any tile actually slid or merged.
    var moved: Bool
    /// Number of merges that occurred this move.
    var merges: Int
}

/// Pure 2048 board logic. Parameterized size; guards every index so it never
/// crashes on any size or malformed grid.
struct BoardEngine {
    let size: Int
    private(set) var grid: [[Int]]

    /// Creates an empty board of the given size (clamped to a sane range).
    init(size: Int) {
        let s = max(2, min(8, size))
        self.size = s
        self.grid = Array(repeating: Array(repeating: 0, count: s), count: s)
    }

    /// Adopts an existing grid, repairing it to a square `size`×`size` board if needed.
    init(size: Int, grid: [[Int]]) {
        let s = max(2, min(8, size))
        self.size = s
        var repaired = Array(repeating: Array(repeating: 0, count: s), count: s)
        for r in 0..<s where r < grid.count {
            let row = grid[r]
            for c in 0..<s where c < row.count {
                repaired[r][c] = max(0, row[c])
            }
        }
        self.grid = repaired
    }

    // MARK: - Queries

    var emptyCells: [(row: Int, col: Int)] {
        var cells: [(Int, Int)] = []
        for r in 0..<size {
            for c in 0..<size where grid[r][c] == 0 {
                cells.append((r, c))
            }
        }
        return cells
    }

    var highestTile: Int {
        var best = 0
        for row in grid {
            for v in row where v > best { best = v }
        }
        return best
    }

    /// True when any tile is at least `target`.
    func hasReached(_ target: Int) -> Bool {
        for row in grid {
            for v in row where v >= target { return true }
        }
        return false
    }

    /// Game over = no empty cells AND no adjacent equal pair in any row or column.
    static func isGameOver(_ grid: [[Int]]) -> Bool {
        let rows = grid.count
        guard rows > 0 else { return false }
        for r in 0..<rows {
            let cols = grid[r].count
            for c in 0..<cols {
                if grid[r][c] == 0 { return false }
                // Right neighbour
                if c + 1 < cols, grid[r][c] == grid[r][c + 1] { return false }
                // Down neighbour
                if r + 1 < rows, c < grid[r + 1].count, grid[r][c] == grid[r + 1][c] {
                    return false
                }
            }
        }
        return true
    }

    func isGameOver() -> Bool { BoardEngine.isGameOver(grid) }

    // MARK: - Moves

    /// Collapses a single line toward index 0: slide non-zeros, merge equal adjacent
    /// pairs once each, then pad with zeros. Returns the new line and points gained.
    static func collapseLine(_ line: [Int]) -> (line: [Int], gained: Int, merges: Int) {
        let tiles = line.filter { $0 != 0 }
        var result: [Int] = []
        var gained = 0
        var merges = 0
        var i = 0
        while i < tiles.count {
            if i + 1 < tiles.count, tiles[i] == tiles[i + 1] {
                let merged = tiles[i] * 2
                result.append(merged)
                gained += merged
                merges += 1
                i += 2 // both tiles consumed; the merged tile can't merge again this move
            } else {
                result.append(tiles[i])
                i += 1
            }
        }
        while result.count < line.count { result.append(0) }
        return (result, gained, merges)
    }

    /// Applies a move in the given direction and returns the result.
    /// Does not mutate `self`; callers apply the returned grid.
    func move(_ direction: Direction) -> MoveResult {
        var newGrid = grid
        var totalGained = 0
        var totalMerges = 0

        switch direction {
        case .left:
            for r in 0..<size {
                let collapsed = BoardEngine.collapseLine(grid[r])
                newGrid[r] = collapsed.line
                totalGained += collapsed.gained
                totalMerges += collapsed.merges
            }
        case .right:
            for r in 0..<size {
                let reversed = Array(grid[r].reversed())
                let collapsed = BoardEngine.collapseLine(reversed)
                newGrid[r] = Array(collapsed.line.reversed())
                totalGained += collapsed.gained
                totalMerges += collapsed.merges
            }
        case .up:
            for c in 0..<size {
                var column = (0..<size).map { grid[$0][c] }
                let collapsed = BoardEngine.collapseLine(column)
                column = collapsed.line
                for r in 0..<size { newGrid[r][c] = column[r] }
                totalGained += collapsed.gained
                totalMerges += collapsed.merges
            }
        case .down:
            for c in 0..<size {
                var column = (0..<size).map { grid[$0][c] }.reversed().map { $0 }
                let collapsed = BoardEngine.collapseLine(column)
                column = Array(collapsed.line.reversed())
                for r in 0..<size { newGrid[r][c] = column[r] }
                totalGained += collapsed.gained
                totalMerges += collapsed.merges
            }
        }

        let moved = newGrid != grid
        return MoveResult(grid: newGrid, gained: totalGained, moved: moved, merges: totalMerges)
    }

    /// Applies the result of a move to this engine's grid.
    mutating func apply(_ result: MoveResult) {
        grid = result.grid
    }

    // MARK: - Spawning

    /// Places a new tile (2 with 90% probability, 4 otherwise) into a random empty
    /// cell using the injected RNG. No-op if the board is full. Returns the placed value.
    @discardableResult
    mutating func spawnTile<G: RandomNumberGenerator>(using rng: inout G) -> Int? {
        let cells = emptyCells
        guard !cells.isEmpty else { return nil }
        let index = Int.random(in: 0..<cells.count, using: &rng)
        let cell = cells[index]
        let value = Int.random(in: 0..<10, using: &rng) == 0 ? 4 : 2
        grid[cell.row][cell.col] = value
        return value
    }
}

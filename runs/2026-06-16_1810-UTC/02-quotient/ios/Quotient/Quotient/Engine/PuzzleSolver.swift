import Foundation

/// A backtracking solver that respects Latin (row/column distinct) plus every
/// cage constraint. It can count solutions up to a cap, which is how the
/// generator guarantees uniqueness.
struct PuzzleSolver {
    let size: Int
    let cages: [Cage]
    private let cageOfCell: [Int]           // cell -> cage array index
    private let cellCount: Int

    init(size: Int, cages: [Cage]) {
        self.size = max(size, 1)
        self.cages = cages
        self.cellCount = self.size * self.size
        var map = [Int](repeating: -1, count: cellCount)
        for (ci, cage) in cages.enumerated() {
            for cell in cage.cells where cell >= 0 && cell < cellCount {
                map[cell] = ci
            }
        }
        self.cageOfCell = map
    }

    /// Counts solutions, stopping early once `cap` are found.
    /// Returns 0 (unsolvable), 1 (unique), or `cap` (>= cap solutions).
    func solutionCount(cap: Int = 2) -> Int {
        guard cellCount > 0, cageOfCell.allSatisfy({ $0 >= 0 }) else { return 0 }
        var grid = [Int](repeating: 0, count: cellCount)   // 0 = empty
        var count = 0
        search(&grid, &count, cap: cap)
        return count
    }

    /// Returns one full solution if the puzzle is solvable, else nil.
    func anySolution() -> [Int]? {
        guard cellCount > 0, cageOfCell.allSatisfy({ $0 >= 0 }) else { return nil }
        var grid = [Int](repeating: 0, count: cellCount)
        if fill(&grid) { return grid }
        return nil
    }

    // MARK: - Counting search

    private func search(_ grid: inout [Int], _ count: inout Int, cap: Int) {
        if count >= cap { return }
        guard let cell = nextEmptyCell(grid) else {
            count += 1
            return
        }
        for value in 1...size {
            if canPlace(value, at: cell, in: grid) {
                grid[cell] = value
                search(&grid, &count, cap: cap)
                grid[cell] = 0
                if count >= cap { return }
            }
        }
    }

    // MARK: - Single-solution fill (used for any-solution)

    private func fill(_ grid: inout [Int]) -> Bool {
        guard let cell = nextEmptyCell(grid) else { return true }
        for value in 1...size {
            if canPlace(value, at: cell, in: grid) {
                grid[cell] = value
                if fill(&grid) { return true }
                grid[cell] = 0
            }
        }
        return false
    }

    // MARK: - Heuristics & constraint checks

    /// Pick the next empty cell in row-major order. Simple and reliable; the
    /// cage pruning keeps the branching factor low enough.
    private func nextEmptyCell(_ grid: [Int]) -> Int? {
        for i in 0..<cellCount where grid[i] == 0 { return i }
        return nil
    }

    private func canPlace(_ value: Int, at cell: Int, in grid: [Int]) -> Bool {
        let row = cell / size
        let col = cell % size

        // Latin: no duplicate in row or column.
        for k in 0..<size {
            if grid[row * size + k] == value { return false }
            if grid[k * size + col] == value { return false }
        }

        // Cage feasibility with this tentative value.
        let ci = cageOfCell[cell]
        guard ci >= 0 && ci < cages.count else { return false }
        return cageFeasible(cages[ci], placing: value, at: cell, in: grid)
    }

    /// Checks that placing `value` at `cell` keeps the cage satisfiable.
    /// When the cage becomes fully filled, the target must match exactly.
    private func cageFeasible(_ cage: Cage, placing value: Int, at cell: Int, in grid: [Int]) -> Bool {
        var values: [Int] = []
        var filledCount = 0
        for c in cage.cells {
            let v = (c == cell) ? value : grid[c]
            if v != 0 {
                values.append(v)
                filledCount += 1
            }
        }
        let complete = filledCount == cage.cells.count

        switch cage.op {
        case .given:
            // Single cell; must equal target.
            return value == cage.target

        case .add:
            let sum = values.reduce(0, +)
            if complete { return sum == cage.target }
            // Partial: can't already exceed; remaining cells add >= 1 each.
            let remaining = cage.cells.count - filledCount
            return sum < cage.target && sum + remaining <= cage.target

        case .multiply:
            // Product must divide target and not overshoot.
            var product = 1
            for v in values { product *= v }
            if complete { return product == cage.target }
            if product == 0 { return false }
            return cage.target % product == 0

        case .subtract:
            // Size-2 cages only.
            guard cage.cells.count == 2 else { return false }
            if complete {
                guard values.count == 2 else { return false }
                return abs(values[0] - values[1]) == cage.target
            }
            return true  // one value known; any partner could still work

        case .divide:
            guard cage.cells.count == 2 else { return false }
            if complete {
                guard values.count == 2 else { return false }
                let hi = max(values[0], values[1])
                let lo = min(values[0], values[1])
                guard lo > 0 else { return false }
                return hi % lo == 0 && hi / lo == cage.target
            }
            return true
        }
    }
}

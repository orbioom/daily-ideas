import Foundation

/// Validates a (possibly partial) grid against Latin-square and cage rules.
enum PuzzleValidator {

    /// Checks whether `values` (1...size or nil) satisfies the cage given the
    /// current entries. A cage is only judged once *fully* filled; a partially
    /// filled cage is considered "not yet violated" (returns true) unless it is
    /// already impossible — but for conflict highlighting we only flag complete
    /// cages, so partial cages return true here.
    static func cageSatisfied(_ cage: Cage, values: [Int?], size: Int) -> Bool {
        let entries = cage.cells.compactMap { idx -> Int? in
            (idx >= 0 && idx < values.count) ? values[idx] : nil
        }
        // Only evaluate when every cell in the cage has a value.
        guard entries.count == cage.cells.count, !entries.isEmpty else { return true }

        switch cage.op {
        case .given:
            return entries.count == 1 && entries[0] == cage.target
        case .add:
            return entries.reduce(0, +) == cage.target
        case .multiply:
            return entries.reduce(1, *) == cage.target
        case .subtract:
            // Defined for size-2 cages: |a - b|.
            guard entries.count == 2 else { return false }
            return abs(entries[0] - entries[1]) == cage.target
        case .divide:
            // Defined for size-2 cages: larger / smaller, must divide evenly.
            guard entries.count == 2 else { return false }
            let hi = max(entries[0], entries[1])
            let lo = min(entries[0], entries[1])
            guard lo > 0 else { return false }
            return hi % lo == 0 && hi / lo == cage.target
        }
    }

    /// Returns the set of cell indices currently in conflict:
    /// - duplicate value within a row or column (Latin violation), and
    /// - any cell belonging to a fully-filled cage that violates its target.
    static func conflicts(values: [Int?], puzzle: Puzzle) -> Set<Int> {
        let size = puzzle.size
        guard size > 0 else { return [] }
        var conflicts = Set<Int>()

        // Row / column duplicates.
        for line in 0..<size {
            // Row `line`.
            var seenRow: [Int: [Int]] = [:]
            var seenCol: [Int: [Int]] = [:]
            for k in 0..<size {
                let rowIdx = Puzzle.index(row: line, col: k, size: size)
                if rowIdx < values.count, let v = values[rowIdx] {
                    seenRow[v, default: []].append(rowIdx)
                }
                let colIdx = Puzzle.index(row: k, col: line, size: size)
                if colIdx < values.count, let v = values[colIdx] {
                    seenCol[v, default: []].append(colIdx)
                }
            }
            for (_, idxs) in seenRow where idxs.count > 1 { conflicts.formUnion(idxs) }
            for (_, idxs) in seenCol where idxs.count > 1 { conflicts.formUnion(idxs) }
        }

        // Fully-filled cages that violate their target.
        for cage in puzzle.cages {
            let filled = cage.cells.allSatisfy { idx in
                idx >= 0 && idx < values.count && values[idx] != nil
            }
            if filled && !cageSatisfied(cage, values: values, size: size) {
                conflicts.formUnion(cage.cells)
            }
        }
        return conflicts
    }

    /// True when the grid is completely and correctly filled.
    static func isSolved(values: [Int?], puzzle: Puzzle) -> Bool {
        let size = puzzle.size
        guard size > 0, values.count == puzzle.cellCount else { return false }
        // Every cell filled with a legal value.
        for v in values {
            guard let val = v, val >= 1, val <= size else { return false }
        }
        return conflicts(values: values, puzzle: puzzle).isEmpty
            && puzzle.cages.allSatisfy { cageSatisfied($0, values: values, size: size) }
    }
}

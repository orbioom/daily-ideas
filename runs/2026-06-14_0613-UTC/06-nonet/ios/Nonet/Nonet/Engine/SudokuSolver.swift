import Foundation

/// A puzzle grid is represented as `[Int]` of length 81. 0 = empty, 1...9 = filled.
/// All indexing is bounds-checked; this type never force-unwraps or traps on user paths.
///
/// `SudokuSolver` provides:
///  - constraint validity checks (row / column / 3x3 box),
///  - `solutionCount(maxToFind:)` via backtracking (to verify uniqueness),
///  - a logical solver that applies human techniques in order and reports the hardest
///    technique required, which drives difficulty grading.
///
/// Candidate bitmasks are used for speed: bit (d-1) set means digit d is a candidate.
enum SudokuSolver {

    // MARK: - Shared geometry

    /// Cells in the same unit (row, column, box) as `index`, excluding itself.
    /// Precomputed once for speed. Index is bounds-checked before use.
    static let peers: [[Int]] = {
        var result = [[Int]](repeating: [], count: 81)
        for index in 0..<81 {
            let row = index / 9
            let col = index % 9
            let boxRow = (row / 3) * 3
            let boxCol = (col / 3) * 3
            var set = Set<Int>()
            for c in 0..<9 where c != col { set.insert(row * 9 + c) }
            for r in 0..<9 where r != row { set.insert(r * 9 + col) }
            for r in boxRow..<(boxRow + 3) {
                for c in boxCol..<(boxCol + 3) where !(r == row && c == col) {
                    set.insert(r * 9 + c)
                }
            }
            result[index] = Array(set).sorted()
        }
        return result
    }()

    /// The 27 units (9 rows, 9 columns, 9 boxes), each a list of cell indices.
    static let units: [[Int]] = {
        var result = [[Int]]()
        // Rows
        for r in 0..<9 { result.append((0..<9).map { r * 9 + $0 }) }
        // Columns
        for c in 0..<9 { result.append((0..<9).map { $0 * 9 + c }) }
        // Boxes
        for br in 0..<3 {
            for bc in 0..<3 {
                var box = [Int]()
                for r in 0..<3 {
                    for c in 0..<3 {
                        box.append((br * 3 + r) * 9 + (bc * 3 + c))
                    }
                }
                result.append(box)
            }
        }
        return result
    }()

    // MARK: - Validity

    /// True if placing `value` (1...9) at `index` violates no row/col/box constraint.
    static func isValidPlacement(_ grid: [Int], index: Int, value: Int) -> Bool {
        guard grid.count == 81, index >= 0, index < 81, value >= 1, value <= 9 else { return false }
        for peer in peers[index] where peer >= 0 && peer < 81 {
            if grid[peer] == value { return false }
        }
        return true
    }

    /// True if the entire grid currently has no duplicate in any unit (ignores empties).
    static func isConsistent(_ grid: [Int]) -> Bool {
        guard grid.count == 81 else { return false }
        for unit in units {
            var seen = 0
            for cell in unit where cell >= 0 && cell < 81 {
                let v = grid[cell]
                if v == 0 { continue }
                let bit = 1 << (v - 1)
                if seen & bit != 0 { return false }
                seen |= bit
            }
        }
        return true
    }

    /// Indices that conflict with another filled cell in a shared unit.
    static func conflicts(in grid: [Int]) -> Set<Int> {
        guard grid.count == 81 else { return [] }
        var bad = Set<Int>()
        for index in 0..<81 {
            let v = grid[index]
            if v == 0 { continue }
            for peer in peers[index] where peer >= 0 && peer < 81 {
                if grid[peer] == v { bad.insert(index); break }
            }
        }
        return bad
    }

    // MARK: - Candidate masks

    /// 9-bit candidate mask for each cell (bit d-1). Filled cells get mask 0.
    static func candidateMasks(_ grid: [Int]) -> [Int] {
        guard grid.count == 81 else { return [Int](repeating: 0, count: 81) }
        var masks = [Int](repeating: 0, count: 81)
        for index in 0..<81 {
            if grid[index] != 0 { masks[index] = 0; continue }
            var used = 0
            for peer in peers[index] where peer >= 0 && peer < 81 {
                let v = grid[peer]
                if v != 0 { used |= 1 << (v - 1) }
            }
            masks[index] = (~used) & 0x1FF
        }
        return masks
    }

    private static func bitCount(_ mask: Int) -> Int { mask.nonzeroBitCount }

    /// The single digit (1...9) encoded by a one-hot mask, else nil.
    private static func soleDigit(_ mask: Int) -> Int? {
        guard mask != 0, mask & (mask - 1) == 0 else { return nil }
        return mask.trailingZeroBitCount + 1
    }

    // MARK: - Backtracking solution count (uniqueness)

    /// Counts solutions up to `maxToFind` (default 2 — enough to test uniqueness).
    /// Uses minimum-remaining-value heuristic with bitmasks. Always terminates.
    static func solutionCount(_ grid: [Int], maxToFind: Int = 2) -> Int {
        guard grid.count == 81 else { return 0 }
        var work = grid
        var found = 0
        _ = solveCount(&work, found: &found, limit: max(1, maxToFind))
        return found
    }

    /// Returns a completed solution if one exists, else nil. Deterministic order.
    static func solve(_ grid: [Int]) -> [Int]? {
        guard grid.count == 81, isConsistent(grid) else { return nil }
        var work = grid
        if fillSolution(&work) { return work }
        return nil
    }

    private static func solveCount(_ grid: inout [Int], found: inout Int, limit: Int) -> Bool {
        // Find the empty cell with fewest candidates (MRV).
        var bestIndex = -1
        var bestMask = 0
        var bestCount = 10
        for index in 0..<81 where grid[index] == 0 {
            var used = 0
            for peer in peers[index] where peer >= 0 && peer < 81 {
                let v = grid[peer]
                if v != 0 { used |= 1 << (v - 1) }
            }
            let mask = (~used) & 0x1FF
            let count = bitCount(mask)
            if count == 0 { return false } // dead end
            if count < bestCount {
                bestCount = count
                bestIndex = index
                bestMask = mask
                if count == 1 { break }
            }
        }
        if bestIndex == -1 {
            // No empty cells: a full solution.
            found += 1
            return found >= limit
        }
        var mask = bestMask
        while mask != 0 {
            let bit = mask & (-mask)
            mask &= mask - 1
            let digit = bit.trailingZeroBitCount + 1
            grid[bestIndex] = digit
            if solveCount(&grid, found: &found, limit: limit) { grid[bestIndex] = 0; return true }
            grid[bestIndex] = 0
        }
        return false
    }

    private static func fillSolution(_ grid: inout [Int]) -> Bool {
        var bestIndex = -1
        var bestMask = 0
        var bestCount = 10
        for index in 0..<81 where grid[index] == 0 {
            var used = 0
            for peer in peers[index] where peer >= 0 && peer < 81 {
                let v = grid[peer]
                if v != 0 { used |= 1 << (v - 1) }
            }
            let mask = (~used) & 0x1FF
            let count = bitCount(mask)
            if count == 0 { return false }
            if count < bestCount { bestCount = count; bestIndex = index; bestMask = mask; if count == 1 { break } }
        }
        if bestIndex == -1 { return true }
        var mask = bestMask
        while mask != 0 {
            let bit = mask & (-mask)
            mask &= mask - 1
            grid[bestIndex] = bit.trailingZeroBitCount + 1
            if fillSolution(&grid) { return true }
            grid[bestIndex] = 0
        }
        return false
    }

    // MARK: - Logical solver & grading

    /// A single logical deduction the solver can surface as a hint.
    struct Deduction {
        let index: Int
        let value: Int
        let technique: SolveTechnique
        let explanation: String
    }

    /// Result of attempting to logically solve a puzzle.
    struct GradeResult {
        let solvable: Bool             // solved using only the implemented techniques
        let hardest: SolveTechnique    // hardest technique required (only meaningful if solvable)
    }

    /// Attempts to solve `grid` using human techniques in increasing difficulty,
    /// always preferring the easiest applicable technique. Returns whether it fully
    /// solved and the hardest technique it had to use. Always terminates (each pass
    /// must make progress or it stops).
    static func grade(_ grid: [Int]) -> GradeResult {
        guard grid.count == 81 else { return GradeResult(solvable: false, hardest: .nakedSingle) }
        var work = grid
        var hardest = SolveTechnique.nakedSingle
        var guardCounter = 0
        while work.contains(0) {
            guardCounter += 1
            if guardCounter > 81 * 10 { break } // safety cap; cannot loop forever
            if let d = nextDeduction(work) {
                if work[d.index] == 0, isValidPlacement(work, index: d.index, value: d.value) {
                    work[d.index] = d.value
                    if d.technique > hardest { hardest = d.technique }
                    continue
                } else {
                    break
                }
            } else {
                break
            }
        }
        return GradeResult(solvable: !work.contains(0), hardest: hardest)
    }

    /// Returns the single easiest next logical step for the current grid, or nil.
    /// Used both for grading and for the in-game hint.
    static func nextDeduction(_ grid: [Int]) -> Deduction? {
        guard grid.count == 81, isConsistent(grid) else { return nil }
        var masks = candidateMasks(grid)

        if let d = nakedSingle(grid, masks) { return d }
        if let d = hiddenSingle(grid, masks) { return d }
        // Locked candidates & pairs do not directly place a digit; they eliminate
        // candidates. Apply them to the masks, then re-test singles, attributing the
        // resulting placement to the elimination technique that unlocked it.
        if applyLockedCandidates(grid, &masks) {
            if let d = nakedSingle(grid, masks) { return Deduction(index: d.index, value: d.value, technique: .lockedCandidate, explanation: "Locked candidates remove options elsewhere, leaving \(d.value) as the only choice for this cell.") }
            if let d = hiddenSingle(grid, masks) { return Deduction(index: d.index, value: d.value, technique: .lockedCandidate, explanation: "Locked candidates remove options in this unit, so \(d.value) can only go here.") }
        }
        if applyPairs(grid, &masks) {
            if let d = nakedSingle(grid, masks) { return Deduction(index: d.index, value: d.value, technique: .pair, explanation: "A pair removes shared candidates from peers, leaving \(d.value) alone in this cell.") }
            if let d = hiddenSingle(grid, masks) { return Deduction(index: d.index, value: d.value, technique: .pair, explanation: "A pair confines two digits, so \(d.value) is forced here.") }
        }
        return nil
    }

    // MARK: Technique: Naked Single

    private static func nakedSingle(_ grid: [Int], _ masks: [Int]) -> Deduction? {
        for index in 0..<81 where grid[index] == 0 {
            if let digit = soleDigit(masks[index]) {
                let row = index / 9 + 1, col = index % 9 + 1
                return Deduction(index: index, value: digit, technique: .nakedSingle,
                                 explanation: "Row \(row), column \(col) has only one possible digit: \(digit).")
            }
        }
        return nil
    }

    // MARK: Technique: Hidden Single

    private static func hiddenSingle(_ grid: [Int], _ masks: [Int]) -> Deduction? {
        for unit in units {
            for digit in 1...9 {
                let bit = 1 << (digit - 1)
                var spot = -1
                var count = 0
                var alreadyPlaced = false
                for cell in unit where cell >= 0 && cell < 81 {
                    if grid[cell] == digit { alreadyPlaced = true; break }
                    if grid[cell] == 0, masks[cell] & bit != 0 { count += 1; spot = cell }
                }
                if alreadyPlaced { continue }
                if count == 1, spot >= 0 {
                    let row = spot / 9 + 1, col = spot % 9 + 1
                    return Deduction(index: spot, value: digit, technique: .hiddenSingle,
                                     explanation: "In this unit, \(digit) can only go at row \(row), column \(col).")
                }
            }
        }
        return nil
    }

    // MARK: Technique: Locked Candidates (pointing / claiming)

    /// Eliminates candidates via pointing/claiming. Returns true if it changed masks.
    private static func applyLockedCandidates(_ grid: [Int], _ masks: inout [Int]) -> Bool {
        var changed = false
        // For each box and digit: if all candidate cells for that digit lie in one
        // row/col, remove the digit from the rest of that row/col (pointing).
        for br in 0..<3 {
            for bc in 0..<3 {
                var boxCells = [Int]()
                for r in 0..<3 {
                    for c in 0..<3 { boxCells.append((br * 3 + r) * 9 + (bc * 3 + c)) }
                }
                for digit in 1...9 {
                    let bit = 1 << (digit - 1)
                    let spots = boxCells.filter { grid[$0] == 0 && masks[$0] & bit != 0 }
                    if spots.count < 2 { continue }
                    let rows = Set(spots.map { $0 / 9 })
                    let cols = Set(spots.map { $0 % 9 })
                    if rows.count == 1, let row = rows.first {
                        for c in 0..<9 {
                            let cell = row * 9 + c
                            if !boxCells.contains(cell), grid[cell] == 0, masks[cell] & bit != 0 {
                                masks[cell] &= ~bit; changed = true
                            }
                        }
                    }
                    if cols.count == 1, let col = cols.first {
                        for r in 0..<9 {
                            let cell = r * 9 + col
                            if !boxCells.contains(cell), grid[cell] == 0, masks[cell] & bit != 0 {
                                masks[cell] &= ~bit; changed = true
                            }
                        }
                    }
                }
            }
        }
        // Claiming: if all candidate cells for a digit in a row/col lie in one box,
        // remove the digit from the rest of that box.
        for line in 0..<9 {
            let rowCells = (0..<9).map { line * 9 + $0 }
            let colCells = (0..<9).map { $0 * 9 + line }
            for lineCells in [rowCells, colCells] {
                for digit in 1...9 {
                    let bit = 1 << (digit - 1)
                    let spots = lineCells.filter { grid[$0] == 0 && masks[$0] & bit != 0 }
                    if spots.count < 2 { continue }
                    let boxes = Set(spots.map { ($0 / 9 / 3) * 3 + ($0 % 9 / 3) })
                    if boxes.count == 1, let box = boxes.first {
                        let br = (box / 3) * 3, bc = (box % 3) * 3
                        for r in 0..<3 {
                            for c in 0..<3 {
                                let cell = (br + r) * 9 + (bc + c)
                                if !lineCells.contains(cell), grid[cell] == 0, masks[cell] & bit != 0 {
                                    masks[cell] &= ~bit; changed = true
                                }
                            }
                        }
                    }
                }
            }
        }
        return changed
    }

    // MARK: Technique: Naked & Hidden Pairs

    /// Eliminates candidates via naked pairs and hidden pairs within each unit.
    private static func applyPairs(_ grid: [Int], _ masks: inout [Int]) -> Bool {
        var changed = false
        for unit in units {
            let emptyCells = unit.filter { $0 >= 0 && $0 < 81 && grid[$0] == 0 }
            // Naked pairs: two cells sharing the same 2-candidate mask -> remove those
            // two digits from the rest of the unit.
            for i in 0..<emptyCells.count {
                let a = emptyCells[i]
                if bitCount(masks[a]) != 2 { continue }
                for j in (i + 1)..<emptyCells.count {
                    let b = emptyCells[j]
                    if masks[b] == masks[a] {
                        let pairMask = masks[a]
                        for cell in emptyCells where cell != a && cell != b {
                            if masks[cell] & pairMask != 0 {
                                masks[cell] &= ~pairMask; changed = true
                            }
                        }
                    }
                }
            }
            // Hidden pairs: two digits that appear (as candidates) only in the same two
            // cells -> those cells are restricted to exactly that pair.
            for d1 in 1...8 {
                for d2 in (d1 + 1)...9 {
                    let b1 = 1 << (d1 - 1), b2 = 1 << (d2 - 1)
                    let cells1 = emptyCells.filter { masks[$0] & b1 != 0 }
                    let cells2 = emptyCells.filter { masks[$0] & b2 != 0 }
                    if cells1.count == 2, cells2.count == 2, Set(cells1) == Set(cells2) {
                        let pairMask = b1 | b2
                        for cell in cells1 {
                            if masks[cell] & ~pairMask != 0 {
                                masks[cell] &= pairMask; changed = true
                            }
                        }
                    }
                }
            }
        }
        return changed
    }
}

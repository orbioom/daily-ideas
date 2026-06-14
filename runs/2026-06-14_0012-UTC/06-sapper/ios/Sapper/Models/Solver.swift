import Foundation

/// Logical Minesweeper solver + no-guess board generator.
///
/// The solver determines whether a board is solvable purely by deduction starting
/// from a known-safe first click (and its flood-filled opening). It uses:
///   1. Single-point deduction:
///        - a number whose unknown-neighbor mines are all accounted for by flags
///          → remaining unknown neighbors are safe;
///        - a number whose value minus flags equals its hidden-neighbor count
///          → all those hidden neighbors are mines.
///   2. A subset rule (covers the classic 1-2-1 / 1-1 patterns): if the unknown
///      neighbor set of constraint A is a subset of constraint B's, the difference
///      cells can sometimes be forced safe or mined.
/// If progress stalls and safe cells remain hidden, the board needs a guess.
enum Solver {

    /// Returns true if `engine`'s current mine layout is solvable without guessing,
    /// flood-filling from `firstTap`.
    static func isSolvable(rows: Int, cols: Int, mines: [Bool], firstTap: Int) -> Bool {
        let total = rows * cols
        guard total > 0, mines.count == total, firstTap >= 0, firstTap < total else {
            return false
        }
        // The first tap must itself be safe.
        if mines[firstTap] { return false }

        // Precompute adjacency counts and neighbor lists.
        var adjacent = [Int](repeating: 0, count: total)
        var neighbors = [[Int]](repeating: [], count: total)
        for i in 0..<total {
            let r = i / cols
            let c = i % cols
            var list: [Int] = []
            for dr in -1...1 {
                for dc in -1...1 {
                    if dr == 0 && dc == 0 { continue }
                    let nr = r + dr
                    let nc = c + dc
                    if nr >= 0 && nr < rows && nc >= 0 && nc < cols {
                        list.append(nr * cols + nc)
                    }
                }
            }
            neighbors[i] = list
            if !mines[i] {
                adjacent[i] = list.reduce(0) { $0 + (mines[$1] ? 1 : 0) }
            }
        }

        // State: revealed (known safe + opened), knownMine (flagged by deduction).
        var revealed = [Bool](repeating: false, count: total)
        var knownMine = [Bool](repeating: false, count: total)

        // Flood-fill open from the first tap (same as the real engine opening).
        func open(_ start: Int) {
            var stack = [start]
            while let i = stack.popLast() {
                if revealed[i] || mines[i] { continue }
                revealed[i] = true
                if adjacent[i] == 0 {
                    for n in neighbors[i] where !revealed[n] && !mines[n] {
                        stack.append(n)
                    }
                }
            }
        }
        open(firstTap)

        // Iterate deduction to a fixed point.
        var progressed = true
        while progressed {
            progressed = false

            // 1) Single-point deduction over revealed numbered cells.
            for i in 0..<total where revealed[i] && adjacent[i] > 0 {
                var hiddenNeighbors: [Int] = []
                var flaggedCount = 0
                for n in neighbors[i] {
                    if knownMine[n] { flaggedCount += 1 }
                    else if !revealed[n] { hiddenNeighbors.append(n) }
                }
                if hiddenNeighbors.isEmpty { continue }

                if flaggedCount == adjacent[i] {
                    // All mines accounted for → remaining hidden are safe.
                    for n in hiddenNeighbors {
                        open(n)
                    }
                    progressed = true
                } else if adjacent[i] - flaggedCount == hiddenNeighbors.count {
                    // Every remaining hidden neighbor must be a mine.
                    for n in hiddenNeighbors where !knownMine[n] {
                        knownMine[n] = true
                        progressed = true
                    }
                }
            }
            if progressed { continue }

            // 2) Subset rule. Build constraints: (unknown cells, mines still needed).
            var constraints: [(cells: Set<Int>, need: Int)] = []
            for i in 0..<total where revealed[i] && adjacent[i] > 0 {
                var unknown: Set<Int> = []
                var flagged = 0
                for n in neighbors[i] {
                    if knownMine[n] { flagged += 1 }
                    else if !revealed[n] { unknown.insert(n) }
                }
                if !unknown.isEmpty {
                    constraints.append((unknown, adjacent[i] - flagged))
                }
            }

            for a in 0..<constraints.count {
                for b in 0..<constraints.count where a != b {
                    let ca = constraints[a]
                    let cb = constraints[b]
                    // If A ⊆ B: the difference (B \ A) holds (cb.need - ca.need) mines.
                    if ca.cells.isSubset(of: cb.cells) && ca.cells.count < cb.cells.count {
                        let diff = cb.cells.subtracting(ca.cells)
                        let diffNeed = cb.need - ca.need
                        if diffNeed == 0 {
                            // All difference cells are safe.
                            for n in diff where !revealed[n] && !knownMine[n] {
                                open(n)
                                progressed = true
                            }
                        } else if diffNeed == diff.count {
                            // All difference cells are mines.
                            for n in diff where !knownMine[n] {
                                knownMine[n] = true
                                progressed = true
                            }
                        }
                    }
                }
                if progressed { break }
            }
        }

        // Solvable if every safe cell is revealed.
        for i in 0..<total where !mines[i] && !revealed[i] {
            return false
        }
        return true
    }

    /// Generate a no-guess board: try up to `maxAttempts` random layouts (excluding
    /// the first tap's 3×3) and return the first one the solver clears. If none is
    /// found, returns `nil` (caller falls back to a plain board).
    static func generateNoGuess(rows: Int,
                                cols: Int,
                                mines: Int,
                                firstTap: Int,
                                rng: inout SplitMix64,
                                maxAttempts: Int = 200) -> Set<Int>? {
        let total = rows * cols
        guard total > 0, firstTap >= 0, firstTap < total else { return nil }

        // Forbidden zone: first tap + neighbors.
        var forbidden = Set<Int>()
        forbidden.insert(firstTap)
        let fr = firstTap / cols
        let fc = firstTap % cols
        for dr in -1...1 {
            for dc in -1...1 {
                let nr = fr + dr
                let nc = fc + dc
                if nr >= 0 && nr < rows && nc >= 0 && nc < cols {
                    forbidden.insert(nr * cols + nc)
                }
            }
        }

        var pool: [Int] = []
        for i in 0..<total where !forbidden.contains(i) { pool.append(i) }
        let placeable = min(mines, pool.count)
        guard placeable > 0 else { return Set<Int>() }

        for _ in 0..<max(1, maxAttempts) {
            // Partial Fisher–Yates shuffle to pick `placeable` mine cells.
            var local = pool
            for k in 0..<placeable {
                let span = local.count - k
                let j = k + Int(rng.next() % UInt64(span))
                local.swapAt(k, j)
            }
            let mineSet = Set(local.prefix(placeable))
            var mineFlags = [Bool](repeating: false, count: total)
            for idx in mineSet { mineFlags[idx] = true }
            if isSolvable(rows: rows, cols: cols, mines: mineFlags, firstTap: firstTap) {
                return mineSet
            }
        }
        return nil
    }
}

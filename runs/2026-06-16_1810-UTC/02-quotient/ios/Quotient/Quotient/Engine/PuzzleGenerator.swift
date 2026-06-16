import Foundation

/// Generates uniquely-solvable Calcudoku/KenKen puzzles.
///
/// Pipeline:
///   1. Build a random Latin square (deterministic for the seed).
///   2. Partition the grid into cages via randomized flood growth.
///   3. Assign each cage an operation consistent with its solution values.
///   4. Verify uniqueness with the backtracking solver (count up to 2).
///   5. Retry (re-partition / re-assign) until unique or the retry cap is hit;
///      fall back to a bundled known-good puzzle if all else fails.
///
/// The generator is *pure*: same seed + difficulty -> same puzzle.
struct PuzzleGenerator {

    let difficulty: Difficulty

    /// Generates a unique puzzle. `seed` drives all randomness so dailies are
    /// deterministic. This never returns a non-unique or unsolvable puzzle.
    func generate(seed: UInt64) -> Puzzle {
        var rng = SplitMix64(seed: seed)
        let size = difficulty.size
        let solution = latinSquare(size: size, rng: &rng)

        let maxRetries = 60
        for attempt in 0..<maxRetries {
            // Vary the partition slightly per attempt by perturbing the seed.
            var attemptRNG = SplitMix64(seed: seed &+ UInt64(attempt) &* 0x9E3779B97F4A7C15)
            let cageCellGroups = partition(size: size, rng: &attemptRNG)
            let cages = assignOperations(
                groups: cageCellGroups,
                solution: solution,
                size: size,
                rng: &attemptRNG
            )
            let puzzle = Puzzle(size: size, solution: solution, cages: cages)

            // Sanity: every cell covered exactly once.
            guard isCompletePartition(cages, cellCount: size * size) else { continue }

            let solver = PuzzleSolver(size: size, cages: cages)
            if solver.solutionCount(cap: 2) == 1 {
                return puzzle
            }
        }

        // Fallback A: a size-2 dominoes partition, which is highly likely unique
        // and keeps the correct grid size.
        var fallbackRNG = SplitMix64(seed: seed ^ 0xDEADBEEFCAFEBABE)
        let dominoGroups = dominoPartition(size: size, rng: &fallbackRNG)
        let dominoCages = assignOperations(
            groups: dominoGroups,
            solution: solution,
            size: size,
            rng: &fallbackRNG
        )
        let dominoPuzzle = Puzzle(size: size, solution: solution, cages: dominoCages)
        if isCompletePartition(dominoCages, cellCount: size * size),
           PuzzleSolver(size: size, cages: dominoCages).solutionCount(cap: 2) == 1 {
            return dominoPuzzle
        }

        // Fallback B (guaranteed, correct size): build from the same domino
        // partition but progressively convert dominoes into single "given" cells
        // until the puzzle is uniquely solvable. Revealing cells can only ever
        // reduce ambiguity, and revealing every cell is trivially unique, so this
        // loop ALWAYS terminates with a unique puzzle of the requested size.
        if let guaranteed = revealUntilUnique(
            groups: dominoGroups,
            solution: solution,
            size: size,
            rng: &fallbackRNG
        ) {
            return guaranteed
        }

        // Absolute last resort (only reachable for size 4 if all else failed):
        // bundled, verified-unique puzzle.
        return size == 4 ? FallbackPuzzles.fourByFour() : allGivens(solution: solution, size: size)
    }

    // MARK: - Latin square

    /// Builds a valid Latin square: start from a cyclic base square then permute
    /// rows, columns, and the symbol set. All three operations preserve the
    /// Latin property, so the result is always a valid Latin square.
    private func latinSquare(size: Int, rng: inout SplitMix64) -> [Int] {
        guard size > 0 else { return [] }
        // Base: cell (r,c) = ((r + c) mod size) + 1
        var grid = [Int](repeating: 0, count: size * size)
        for r in 0..<size {
            for c in 0..<size {
                grid[r * size + c] = ((r + c) % size) + 1
            }
        }

        // Permute rows.
        let rowOrder = rng.shuffled(Array(0..<size))
        var rowPermuted = [Int](repeating: 0, count: size * size)
        for (newR, oldR) in rowOrder.enumerated() {
            for c in 0..<size {
                rowPermuted[newR * size + c] = grid[oldR * size + c]
            }
        }

        // Permute columns.
        let colOrder = rng.shuffled(Array(0..<size))
        var colPermuted = [Int](repeating: 0, count: size * size)
        for r in 0..<size {
            for (newC, oldC) in colOrder.enumerated() {
                colPermuted[r * size + newC] = rowPermuted[r * size + oldC]
            }
        }

        // Permute symbols (relabel 1...size).
        let symbols = rng.shuffled(Array(1...size))
        var result = [Int](repeating: 0, count: size * size)
        for i in 0..<colPermuted.count {
            let v = colPermuted[i]
            // v is 1...size; map via symbols (guard the index defensively).
            if v >= 1 && v <= size {
                result[i] = symbols[v - 1]
            } else {
                result[i] = v
            }
        }
        return result
    }

    // MARK: - Partition into cages

    /// Randomized flood growth. Picks an unassigned seed cell, grows a cage by
    /// adding random adjacent unassigned cells up to a target size drawn from
    /// the difficulty's distribution. Bounds-checked throughout.
    private func partition(size: Int, rng: inout SplitMix64) -> [[Int]] {
        let cellCount = size * size
        var assigned = [Int](repeating: -1, count: cellCount)
        var groups: [[Int]] = []

        // Iterate cells in a shuffled order to vary seeds.
        let order = rng.shuffled(Array(0..<cellCount))
        for seedCell in order where assigned[seedCell] == -1 {
            let groupID = groups.count
            var cage = [seedCell]
            assigned[seedCell] = groupID

            let targetSize = randomCageSize(rng: &rng)
            // Grow.
            var frontierGuard = 0
            while cage.count < targetSize && frontierGuard < cellCount {
                frontierGuard += 1
                // Collect unassigned neighbors of any cell in the cage.
                var candidates: [Int] = []
                for cell in cage {
                    for n in neighbors(of: cell, size: size) where assigned[n] == -1 {
                        candidates.append(n)
                    }
                }
                guard !candidates.isEmpty else { break }
                let pick = candidates[rng.int(below: candidates.count)]
                if assigned[pick] == -1 {
                    assigned[pick] = groupID
                    cage.append(pick)
                }
            }
            groups.append(cage)
        }

        // Merge any accidental orphan singletons too aggressively? No — singletons
        // are valid (they become "given" cells). But cap the number of givens so
        // the puzzle stays interesting: merge extra singletons into a neighbor.
        return mergeExcessSingletons(groups, assigned: &assigned, size: size, rng: &rng)
    }

    /// A simple all-dominoes (and trailing singleton) partition for the fallback.
    private func dominoPartition(size: Int, rng: inout SplitMix64) -> [[Int]] {
        let cellCount = size * size
        var assigned = [Bool](repeating: false, count: cellCount)
        var groups: [[Int]] = []
        for cell in 0..<cellCount where !assigned[cell] {
            assigned[cell] = true
            // Try to pair with the cell to the right, then below.
            let neigh = neighbors(of: cell, size: size).filter { !assigned[$0] }
            if let partner = neigh.first {
                assigned[partner] = true
                groups.append([cell, partner])
            } else {
                groups.append([cell])
            }
        }
        return groups
    }

    /// The cage-size distribution by difficulty. Harder = a few larger cages.
    private func randomCageSize(rng: inout SplitMix64) -> Int {
        let roll = rng.int(below: 100)
        switch difficulty {
        case .easy:
            // mostly 2, some 1 and 3
            if roll < 15 { return 1 }
            if roll < 75 { return 2 }
            return 3
        case .medium:
            if roll < 10 { return 1 }
            if roll < 60 { return 2 }
            if roll < 92 { return 3 }
            return 4
        case .hard:
            if roll < 8 { return 1 }
            if roll < 48 { return 2 }
            if roll < 85 { return 3 }
            return 4
        case .expert:
            if roll < 6 { return 1 }
            if roll < 40 { return 2 }
            if roll < 80 { return 3 }
            return 4
        }
    }

    /// Limits the count of singleton cages by merging surplus ones into an
    /// adjacent cage. Keeps at most a couple of givens.
    private func mergeExcessSingletons(
        _ groups: [[Int]],
        assigned: inout [Int],
        size: Int,
        rng: inout SplitMix64
    ) -> [[Int]] {
        let maxGivens: Int
        switch difficulty {
        case .easy:   maxGivens = 2
        case .medium: maxGivens = 2
        case .hard:   maxGivens = 1
        case .expert: maxGivens = 1
        }

        var result = groups
        // Rebuild cell -> group index.
        func rebuildMap() -> [Int] {
            var map = [Int](repeating: -1, count: size * size)
            for (gi, g) in result.enumerated() {
                for c in g where c >= 0 && c < map.count { map[c] = gi }
            }
            return map
        }
        var map = rebuildMap()

        var singletonIndices = result.indices.filter { result[$0].count == 1 }
        // Keep `maxGivens`, merge the rest.
        guard singletonIndices.count > maxGivens else { return result }
        singletonIndices = rng.shuffled(singletonIndices)
        let toMerge = singletonIndices.dropFirst(maxGivens)

        // Merge each surplus singleton into a neighboring group (mark merged
        // groups empty, then compact at the end).
        var removed = Set<Int>()
        for gi in toMerge {
            guard let cell = result[gi].first else { continue }
            let neigh = neighbors(of: cell, size: size)
            // Find a neighbor whose group is not this one and not already removed.
            var mergedInto: Int? = nil
            for n in neigh {
                let ng = map[n]
                if ng >= 0 && ng != gi && !removed.contains(ng) {
                    mergedInto = ng
                    break
                }
            }
            if let target = mergedInto {
                result[target].append(cell)
                result[gi] = []
                removed.insert(gi)
                map = rebuildMap()
            }
        }
        // Compact, dropping empties.
        let compacted = result.filter { !$0.isEmpty }
        // Refresh `assigned` for callers (not strictly required downstream).
        assigned = [Int](repeating: -1, count: size * size)
        for (gi, g) in compacted.enumerated() {
            for c in g where c >= 0 && c < assigned.count { assigned[c] = gi }
        }
        return compacted
    }

    // MARK: - Operation assignment

    /// Assigns each cage a CageOp consistent with its actual solution values, so
    /// the puzzle is solvable by construction. Targets are computed from cells.
    private func assignOperations(
        groups: [[Int]],
        solution: [Int],
        size: Int,
        rng: inout SplitMix64
    ) -> [Cage] {
        var cages: [Cage] = []
        for (id, cells) in groups.enumerated() {
            let sorted = cells.sorted()
            let values = sorted.compactMap { idx -> Int? in
                (idx >= 0 && idx < solution.count) ? solution[idx] : nil
            }
            guard values.count == sorted.count, !values.isEmpty else { continue }

            let op: CageOp
            let target: Int

            if sorted.count == 1 {
                op = .given
                target = values[0]
            } else if sorted.count == 2 {
                let a = values[0]
                let b = values[1]
                let hi = max(a, b)
                let lo = min(a, b)
                let canDivide = lo > 0 && hi % lo == 0 && hi != lo
                // Probability of subtract/divide increases with difficulty.
                let subDivChance: Int
                switch difficulty {
                case .easy:   subDivChance = 35
                case .medium: subDivChance = 50
                case .hard:   subDivChance = 65
                case .expert: subDivChance = 75
                }
                let roll = rng.int(below: 100)
                if roll < subDivChance {
                    if canDivide && rng.int(below: 2) == 0 {
                        op = .divide
                        target = hi / lo
                    } else {
                        op = .subtract
                        target = hi - lo
                    }
                } else {
                    // add or multiply
                    if rng.int(below: 2) == 0 {
                        op = .add
                        target = a + b
                    } else {
                        op = .multiply
                        target = a * b
                    }
                }
            } else {
                // size >= 3: add or multiply only.
                if rng.int(below: 2) == 0 {
                    op = .add
                    target = values.reduce(0, +)
                } else {
                    op = .multiply
                    target = values.reduce(1, *)
                }
            }

            cages.append(Cage(id: id, cells: sorted, op: op, target: target))
        }
        return cages
    }

    // MARK: - Guaranteed-unique fallback

    /// Starting from a domino partition, repeatedly split the least-helpful
    /// cage into single "given" cells until the puzzle is uniquely solvable.
    /// Because revealing a cell never adds solutions and the all-given board is
    /// trivially unique, this always returns a unique puzzle at the right size.
    private func revealUntilUnique(
        groups: [[Int]],
        solution: [Int],
        size: Int,
        rng: inout SplitMix64
    ) -> Puzzle? {
        var workingGroups = groups
        // Process multi-cell cages in a shuffled order, converting each to
        // givens one at a time and re-checking uniqueness.
        let multiOrder = rng.shuffled(workingGroups.indices.filter { workingGroups[$0].count > 1 })

        for gi in multiOrder {
            // Replace cage `gi` with single-cell groups (givens).
            let cells = workingGroups[gi]
            workingGroups[gi] = [cells[0]]
            for extra in cells.dropFirst() {
                workingGroups.append([extra])
            }
            let cages = assignOperations(groups: workingGroups, solution: solution, size: size, rng: &rng)
            guard isCompletePartition(cages, cellCount: size * size) else { continue }
            if PuzzleSolver(size: size, cages: cages).solutionCount(cap: 2) == 1 {
                return Puzzle(size: size, solution: solution, cages: cages)
            }
        }

        // If still not unique (shouldn't happen), every cell is now a given,
        // which is unique by definition.
        let finalCages = assignOperations(groups: workingGroups, solution: solution, size: size, rng: &rng)
        if isCompletePartition(finalCages, cellCount: size * size),
           PuzzleSolver(size: size, cages: finalCages).solutionCount(cap: 2) == 1 {
            return Puzzle(size: size, solution: solution, cages: finalCages)
        }
        return nil
    }

    /// Every cell as its own "given" cage — a trivially unique puzzle of the
    /// correct size. Used only as the theoretical worst case.
    private func allGivens(solution: [Int], size: Int) -> Puzzle {
        var cages: [Cage] = []
        for i in 0..<(size * size) where i < solution.count {
            cages.append(Cage(id: i, cells: [i], op: .given, target: solution[i]))
        }
        return Puzzle(size: size, solution: solution, cages: cages)
    }

    // MARK: - Helpers

    private func neighbors(of cell: Int, size: Int) -> [Int] {
        guard size > 0 else { return [] }
        let r = cell / size
        let c = cell % size
        var result: [Int] = []
        if r > 0 { result.append((r - 1) * size + c) }
        if r < size - 1 { result.append((r + 1) * size + c) }
        if c > 0 { result.append(r * size + (c - 1)) }
        if c < size - 1 { result.append(r * size + (c + 1)) }
        return result
    }

    private func isCompletePartition(_ cages: [Cage], cellCount: Int) -> Bool {
        guard cellCount > 0 else { return false }
        var covered = [Bool](repeating: false, count: cellCount)
        for cage in cages {
            for cell in cage.cells {
                guard cell >= 0 && cell < cellCount else { return false }
                if covered[cell] { return false }   // overlap
                covered[cell] = true
            }
        }
        return covered.allSatisfy { $0 }
    }
}

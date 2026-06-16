import Foundation

/// Pure, deterministic match-3 engine. All randomness flows through an injected
/// SplitMix64 RNG, so a given seed reproduces an entire game exactly.
///
/// Scoring: a group of 3 = 60 points, +20 per extra gem in the group.
/// Cascades multiply the wave score by the chain index (×1, ×2, ×3…).
struct MatchEngine {
    let colors: [GemColor]

    init(colorCount: Int = 6) {
        let n = min(GemColor.allCases.count, max(3, colorCount))
        self.colors = Array(GemColor.allCases.prefix(n))
    }

    private func randomColor(_ rng: inout SplitMix64) -> GemColor {
        let idx = rng.int(below: colors.count)
        // colors is never empty (min 3); guard anyway.
        guard colors.indices.contains(idx) else { return .amethyst }
        return colors[idx]
    }

    // MARK: - Board generation

    /// Builds a full board with NO pre-existing matches (rejects colors that would
    /// complete a run of 3 as it fills, so generation is O(rows*cols)).
    func makeBoard(rows: Int, cols: Int, rng: inout SplitMix64) -> Board {
        var board = Board(rows: rows, cols: cols)
        for r in 0..<board.rows {
            for c in 0..<board.cols {
                var attempts = 0
                var color = randomColor(&rng)
                while wouldStartMatch(board, r, c, color) && attempts < 32 {
                    color = randomColor(&rng)
                    attempts += 1
                }
                board.set(r, c, Gem(color: color))
            }
        }
        // Safety net: if any match slipped through, recolor offenders.
        sanitize(&board, rng: &rng)
        return board
    }

    /// True if placing `color` at (r,c) completes a horizontal/vertical run of 3
    /// with already-filled cells above/left.
    private func wouldStartMatch(_ board: Board, _ r: Int, _ c: Int, _ color: GemColor) -> Bool {
        if c >= 2,
           board.gem(r, c - 1)?.color == color,
           board.gem(r, c - 2)?.color == color {
            return true
        }
        if r >= 2,
           board.gem(r - 1, c)?.color == color,
           board.gem(r - 2, c)?.color == color {
            return true
        }
        return false
    }

    /// Recolor any cell that is part of a match until the board is match-free.
    private func sanitize(_ board: inout Board, rng: inout SplitMix64) {
        var guardCount = 0
        while true {
            let groups = findMatchGroups(board)
            if groups.isEmpty { break }
            for group in groups {
                for cell in group.cells {
                    var color = randomColor(&rng)
                    var tries = 0
                    while wouldStartMatch(board, cell.row, cell.col, color) && tries < 32 {
                        color = randomColor(&rng)
                        tries += 1
                    }
                    if let existing = board.gem(at: cell) {
                        board.set(cell, Gem(id: existing.id, color: color))
                    }
                }
            }
            guardCount += 1
            if guardCount > 64 { break }
        }
    }

    // MARK: - Match detection

    /// A contiguous run of ≥3 same-color gems (row or column), plus whether it is
    /// a length-4 (striped) or length-5 (color bomb) run.
    struct MatchGroup {
        var cells: [Cell]
        var color: GemColor
        var length: Int
        var isHorizontal: Bool
    }

    /// Finds every maximal horizontal and vertical run of ≥3 (overlaps merged later
    /// at clear time; here we return raw runs for special-creation decisions).
    func findMatchGroups(_ board: Board) -> [MatchGroup] {
        var groups: [MatchGroup] = []

        // Horizontal runs
        for r in 0..<board.rows {
            var c = 0
            while c < board.cols {
                guard let color = board.gem(r, c)?.color else { c += 1; continue }
                var end = c + 1
                while end < board.cols, board.gem(r, end)?.color == color {
                    end += 1
                }
                let len = end - c
                if len >= 3 {
                    let cells = (c..<end).map { Cell(row: r, col: $0) }
                    groups.append(MatchGroup(cells: cells, color: color, length: len, isHorizontal: true))
                }
                c = end
            }
        }

        // Vertical runs
        for c in 0..<board.cols {
            var r = 0
            while r < board.rows {
                guard let color = board.gem(r, c)?.color else { r += 1; continue }
                var end = r + 1
                while end < board.rows, board.gem(end, c)?.color == color {
                    end += 1
                }
                let len = end - r
                if len >= 3 {
                    let cells = (r..<end).map { Cell(row: $0, col: c) }
                    groups.append(MatchGroup(cells: cells, color: color, length: len, isHorizontal: false))
                }
                r = end
            }
        }

        return groups
    }

    func hasAnyMatch(_ board: Board) -> Bool {
        !findMatchGroups(board).isEmpty
    }

    // MARK: - Swap resolution

    /// Attempts to swap two adjacent cells. If it forms a match, resolves all
    /// cascades and returns the animation steps; otherwise reports a no-op revert.
    func resolveSwap(on board: Board, swap a: Cell, _ b: Cell, rng: inout SplitMix64) -> SwapOutcome {
        guard board.areAdjacent(a, b),
              let gemA = board.gem(at: a),
              let gemB = board.gem(at: b) else {
            return SwapOutcome(didMatch: false, steps: [], totalScore: 0, maxChain: 0,
                               clearedByColor: [:], totalCleared: 0)
        }

        var work = board
        work.swap(a, b)

        // A color bomb activates on swap against any normal gem (special rule).
        let bombActivation = colorBombSwapTargets(in: work, a: a, b: b, gemA: gemA, gemB: gemB)

        if bombActivation == nil && !hasAnyMatch(work) {
            // No match → revert, no-op.
            return SwapOutcome(didMatch: false, steps: [], totalScore: 0, maxChain: 0,
                               clearedByColor: [:], totalCleared: 0)
        }

        return resolveCascades(start: work, firstBombCells: bombActivation, swap: (a, b), rng: &rng)
    }

    /// If a color bomb is swapped with a normal gem, returns the cells to clear
    /// (all gems of the swapped color + the bomb itself).
    private func colorBombSwapTargets(in board: Board, a: Cell, b: Cell, gemA: Gem, gemB: Gem) -> Set<Cell>? {
        // After swap, gemA is now at b, gemB at a.
        func bombTargets(bombAt: Cell, otherColor: GemColor) -> Set<Cell> {
            var set: Set<Cell> = [bombAt]
            for cell in board.allCells where board.gem(at: cell)?.color == otherColor {
                set.insert(cell)
            }
            return set
        }
        if gemA.power == .colorBomb {
            return bombTargets(bombAt: b, otherColor: gemB.color)
        }
        if gemB.power == .colorBomb {
            return bombTargets(bombAt: a, otherColor: gemA.color)
        }
        return nil
    }

    // MARK: - Cascade loop

    private func resolveCascades(start: Board, firstBombCells: Set<Cell>?, swap: (Cell, Cell), rng: inout SplitMix64) -> SwapOutcome {
        var board = start
        var steps: [ResolveStep] = []
        var total = 0
        var maxChain = 0
        var clearedByColor: [GemColor: Int] = [:]
        var totalCleared = 0
        var chain = 0
        var pendingBomb = firstBombCells
        var guardLoops = 0

        while true {
            guardLoops += 1
            if guardLoops > 256 { break } // hard safety bound

            let groups = findMatchGroups(board)

            // Determine cells to clear this wave + which specials to create.
            var toClear = Set<Cell>()
            var specialsToSpawn: [(cell: Cell, gem: Gem)] = []

            if let bomb = pendingBomb {
                toClear.formUnion(bomb)
                pendingBomb = nil
            }

            if groups.isEmpty && toClear.isEmpty {
                break
            }

            chain += 1
            maxChain = max(maxChain, chain)

            // Expand groups into clears, also activate any specials swept up.
            var activatedExtra = Set<Cell>()
            let preferredSwapCell = (chain == 1) ? swap.1 : nil

            for group in groups {
                for cell in group.cells { toClear.insert(cell) }
                // Specials created from length-4/5 runs.
                if let spawn = specialForGroup(group, board: board, preferredCell: preferredSwapCell) {
                    specialsToSpawn.append(spawn)
                }
            }

            // Activate striped/colorBomb gems that are inside the clear set (chain reaction).
            for cell in toClear {
                if let g = board.gem(at: cell) {
                    let extra = activationCells(of: g, at: cell, board: board)
                    activatedExtra.formUnion(extra)
                }
            }
            toClear.formUnion(activatedExtra)

            // Cells where we'll place a freshly created special must NOT be cleared.
            let spawnCells = Set(specialsToSpawn.map { $0.cell })
            toClear.subtract(spawnCells)

            if toClear.isEmpty && specialsToSpawn.isEmpty { break }

            // Score this wave (only counts gems actually removed).
            let waveScore = scoreForWave(groups: groups, clearedCount: toClear.count, chain: chain)
            total += waveScore

            // Tally cleared gems by color before removal.
            for cell in toClear {
                if let g = board.gem(at: cell) {
                    clearedByColor[g.color, default: 0] += 1
                    totalCleared += 1
                }
            }

            steps.append(.clear(cells: toClear, score: waveScore, chain: chain))

            // Remove cleared gems.
            for cell in toClear { board.set(cell, nil) }

            // Place newly created specials.
            for spawn in specialsToSpawn {
                board.set(spawn.cell, spawn.gem)
                steps.append(.spawnSpecial(cell: spawn.cell, gem: spawn.gem))
            }

            // Gravity + refill.
            applyGravity(&board)
            refill(&board, rng: &rng)
            steps.append(.settle(board: board))
        }

        return SwapOutcome(
            didMatch: !steps.isEmpty,
            steps: steps,
            totalScore: total,
            maxChain: maxChain,
            clearedByColor: clearedByColor,
            totalCleared: totalCleared
        )
    }

    /// Score for a wave: per group 60 + 20*(len-3); whole wave multiplied by chain.
    private func scoreForWave(groups: [MatchGroup], clearedCount: Int, chain: Int) -> Int {
        if groups.isEmpty {
            // Pure special-triggered clear (e.g. color bomb on swap): 40 per gem.
            return clearedCount * 40 * max(1, chain)
        }
        var base = 0
        for g in groups {
            base += 60 + 20 * max(0, g.length - 3)
        }
        return base * max(1, chain)
    }

    // MARK: - Special creation

    /// Decides whether a matched group spawns a special gem, and where.
    private func specialForGroup(_ group: MatchGroup, board: Board, preferredCell: Cell?) -> (cell: Cell, gem: Gem)? {
        guard group.length >= 4 else { return nil }
        // Anchor at the swapped cell if it's part of this group, else the middle.
        let anchor: Cell
        if let pref = preferredCell, group.cells.contains(pref) {
            anchor = pref
        } else {
            let midIndex = group.cells.count / 2
            guard group.cells.indices.contains(midIndex) else { return nil }
            anchor = group.cells[midIndex]
        }

        if group.length >= 5 {
            return (anchor, Gem(color: group.color, power: .colorBomb))
        } else {
            // match-4 → striped (orientation: clears the perpendicular line on use,
            // but for simplicity striped clears its full row OR column).
            return (anchor, Gem(color: group.color, power: .striped))
        }
    }

    // MARK: - Special activation

    /// Cells cleared when a special gem at `cell` is activated.
    private func activationCells(of gem: Gem, at cell: Cell, board: Board) -> Set<Cell> {
        switch gem.power {
        case .none:
            return []
        case .striped:
            // Clear the gem's whole row AND column for a satisfying cross blast.
            var set = Set<Cell>()
            for c in 0..<board.cols { set.insert(Cell(row: cell.row, col: c)) }
            for r in 0..<board.rows { set.insert(Cell(row: r, col: cell.col)) }
            return set
        case .colorBomb:
            // When swept into a match, a color bomb clears all gems of its own color.
            var set = Set<Cell>()
            for c in board.allCells where board.gem(at: c)?.color == gem.color {
                set.insert(c)
            }
            return set
        }
    }

    // MARK: - Gravity & refill

    /// Gems fall to fill empty cells beneath them (per column).
    func applyGravity(_ board: inout Board) {
        for c in 0..<board.cols {
            var writeRow = board.rows - 1
            var r = board.rows - 1
            while r >= 0 {
                if let g = board.gem(r, c) {
                    if writeRow != r {
                        board.set(writeRow, c, g)
                        board.set(r, c, nil)
                    }
                    writeRow -= 1
                }
                r -= 1
            }
        }
    }

    /// Fills empty cells (always at the top after gravity) with fresh random gems.
    func refill(_ board: inout Board, rng: inout SplitMix64) {
        for r in 0..<board.rows {
            for c in 0..<board.cols where board.gem(r, c) == nil {
                board.set(r, c, Gem(color: randomColor(&rng)))
            }
        }
    }

    // MARK: - Possible-move detection & reshuffle

    /// True if any single adjacent swap would create a match (or activate a bomb).
    func hasPossibleMove(_ board: Board) -> Bool {
        for r in 0..<board.rows {
            for c in 0..<board.cols {
                let here = Cell(row: r, col: c)
                guard let g = board.gem(at: here) else { continue }
                if g.power == .colorBomb { return true } // bomb can always activate
                // Try right and down neighbors (covers all adjacency without dupes).
                for n in [Cell(row: r, col: c + 1), Cell(row: r + 1, col: c)] {
                    guard board.inBounds(n) else { continue }
                    var test = board
                    test.swap(here, n)
                    if hasAnyMatch(test) { return true }
                }
            }
        }
        return false
    }

    /// Re-randomizes the board (preserving the multiset of gems would be ideal, but
    /// for clarity we regenerate match-free with a guaranteed possible move).
    func reshuffle(_ board: Board, rng: inout SplitMix64) -> Board {
        var attempts = 0
        var result = makeBoard(rows: board.rows, cols: board.cols, rng: &rng)
        while !hasPossibleMove(result) && attempts < 64 {
            result = makeBoard(rows: board.rows, cols: board.cols, rng: &rng)
            attempts += 1
        }
        return result
    }
}

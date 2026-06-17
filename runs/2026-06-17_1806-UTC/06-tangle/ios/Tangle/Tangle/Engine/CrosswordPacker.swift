import Foundation

enum WordOrientation: String, Codable, Equatable {
    case horizontal
    case vertical
}

/// A single cell coordinate on the crossword grid.
struct GridCoord: Hashable, Codable {
    let row: Int
    let col: Int
}

/// A word that has been successfully placed on the grid.
struct PlacedWord: Identifiable, Equatable {
    let id: Int
    let word: String
    let start: GridCoord
    let orientation: WordOrientation

    /// The coordinates this word occupies, in reading order.
    var cells: [GridCoord] {
        (0..<word.count).map { i in
            switch orientation {
            case .horizontal: return GridCoord(row: start.row, col: start.col + i)
            case .vertical:   return GridCoord(row: start.row + i, col: start.col)
            }
        }
    }
}

/// The fully laid-out crossword for a level.
struct CrosswordLayout: Equatable {
    let rows: Int
    let cols: Int
    /// Letters keyed by coordinate (only filled cells appear).
    let letters: [GridCoord: Character]
    let placed: [PlacedWord]
    /// Target words that could NOT be placed (still count as bonus words).
    let unplaced: [String]

    var isEmpty: Bool { placed.isEmpty }

    func letter(at coord: GridCoord) -> Character? { letters[coord] }
}

/// Deterministic interlocking crossword layout engine.
///
/// Algorithm:
///  1. De-duplicate and sort the target words longest-first (stable tie-break by spelling).
///  2. Place the first word horizontally near the center of a generous virtual grid.
///  3. For each subsequent word, scan every shared-letter intersection against
///     already-placed words and collect all legal placements (no conflicting
///     letters, no illegal side-by-side adjacency where avoidable, endpoints clear).
///  4. Choose the best placement by a deterministic score, breaking ties with a
///     seeded PRNG so a given level id always yields the same board.
///  5. Words that never find a legal placement are reported as `unplaced`.
///  6. Crop the virtual grid to the used bounds and emit a 0-indexed layout.
///
/// Pure and total: it never force-unwraps, never indexes out of range, and
/// returns an empty layout rather than crashing if nothing can be placed.
enum CrosswordPacker {

    // A generous working canvas; cropped at the end.
    private static let canvas = 64
    private static let origin = 32

    private struct Working {
        var grid: [[Character?]]
        var placed: [PlacedWord] = []
        var nextID = 0

        init() {
            grid = Array(repeating: Array(repeating: nil, count: canvas), count: canvas)
        }

        func inBounds(_ r: Int, _ c: Int) -> Bool {
            r >= 0 && r < canvas && c >= 0 && c < canvas
        }

        func cell(_ r: Int, _ c: Int) -> Character? {
            guard inBounds(r, c) else { return nil }
            return grid[r][c]
        }

        mutating func write(_ ch: Character, _ r: Int, _ c: Int) {
            guard inBounds(r, c) else { return }
            grid[r][c] = ch
        }
    }

    static func pack(words rawWords: [String], levelID: String) -> CrosswordLayout {
        // Normalize: uppercase, letters only, de-duplicated, length >= 2.
        var seen = Set<String>()
        var words: [String] = []
        for w in rawWords {
            let clean = String(w.uppercased().filter { $0.isLetter })
            guard clean.count >= 2, !seen.contains(clean) else { continue }
            seen.insert(clean)
            words.append(clean)
        }
        guard !words.isEmpty else {
            return CrosswordLayout(rows: 0, cols: 0, letters: [:], placed: [], unplaced: [])
        }

        // Longest-first, stable tie-break by spelling.
        words.sort { lhs, rhs in
            if lhs.count != rhs.count { return lhs.count > rhs.count }
            return lhs < rhs
        }

        var rng = SeededRandom(seedString: levelID)
        var work = Working()
        var unplaced: [String] = []

        // Place the first word horizontally near center.
        if let first = words.first {
            let chars = Array(first)
            let r = origin
            let c = origin - chars.count / 2
            for (i, ch) in chars.enumerated() { work.write(ch, r, c + i) }
            work.placed.append(PlacedWord(id: work.nextID, word: first,
                                          start: GridCoord(row: r, col: c),
                                          orientation: .horizontal))
            work.nextID += 1
        }

        // Place the rest.
        for word in words.dropFirst() {
            if let placement = bestPlacement(for: word, in: work, rng: &rng) {
                let chars = Array(word)
                switch placement.orientation {
                case .horizontal:
                    for (i, ch) in chars.enumerated() { work.write(ch, placement.start.row, placement.start.col + i) }
                case .vertical:
                    for (i, ch) in chars.enumerated() { work.write(ch, placement.start.row + i, placement.start.col) }
                }
                work.placed.append(PlacedWord(id: work.nextID, word: word,
                                              start: placement.start,
                                              orientation: placement.orientation))
                work.nextID += 1
            } else {
                unplaced.append(word)
            }
        }

        return crop(work, unplaced: unplaced)
    }

    private struct Candidate {
        let start: GridCoord
        let orientation: WordOrientation
        let intersections: Int
        let row: Int
        let col: Int
    }

    /// Find the best legal placement for `word`, or nil if none exists.
    private static func bestPlacement(for word: String, in work: Working,
                                      rng: inout SeededRandom) -> Candidate? {
        let chars = Array(word)
        var candidates: [Candidate] = []

        for placed in work.placed {
            let pChars = Array(placed.word)
            let pCells = placed.cells
            // The new word runs perpendicular to the placed word.
            let newOrientation: WordOrientation = placed.orientation == .horizontal ? .vertical : .horizontal

            for (pi, pCell) in pCells.enumerated() {
                guard pi < pChars.count else { continue }
                let crossLetter = pChars[pi]
                // For each occurrence of crossLetter in the new word, align there.
                for (wi, wCh) in chars.enumerated() where wCh == crossLetter {
                    let start: GridCoord
                    switch newOrientation {
                    case .vertical:
                        start = GridCoord(row: pCell.row - wi, col: pCell.col)
                    case .horizontal:
                        start = GridCoord(row: pCell.row, col: pCell.col - wi)
                    }
                    if let cand = validate(chars: chars, start: start,
                                           orientation: newOrientation, in: work) {
                        candidates.append(cand)
                    }
                }
            }
        }

        guard !candidates.isEmpty else { return nil }

        // Deterministic ranking: more intersections is better (tighter board),
        // then closer to center, then a seeded jitter to break exact ties.
        let center = Double(origin)
        func score(_ c: Candidate) -> Double {
            let dr = Double(c.row) - center
            let dc = Double(c.col) - center
            let dist = (dr * dr + dc * dc).squareRoot()
            return Double(c.intersections) * 1000.0 - dist
        }

        let best = candidates.max { a, b in
            let sa = score(a), sb = score(b)
            if sa != sb { return sa < sb }
            // Tie-break deterministically with the seeded RNG.
            return rng.next() & 1 == 0
        }
        return best
    }

    /// Validate a tentative placement. Returns a scored Candidate when legal.
    private static func validate(chars: [Character], start: GridCoord,
                                 orientation: WordOrientation, in work: Working) -> Candidate? {
        var intersections = 0
        let n = chars.count

        // The cell immediately before the word and immediately after must be empty,
        // so words don't run together end-to-end.
        let beforeR: Int, beforeC: Int, afterR: Int, afterC: Int
        switch orientation {
        case .horizontal:
            beforeR = start.row; beforeC = start.col - 1
            afterR = start.row;  afterC = start.col + n
        case .vertical:
            beforeR = start.row - 1; beforeC = start.col
            afterR = start.row + n;  afterC = start.col
        }
        if work.cell(beforeR, beforeC) != nil { return nil }
        if work.cell(afterR, afterC) != nil { return nil }

        for i in 0..<n {
            let r: Int, c: Int
            switch orientation {
            case .horizontal: r = start.row; c = start.col + i
            case .vertical:   r = start.row + i; c = start.col
            }
            guard work.inBounds(r, c) else { return nil }

            if let existing = work.cell(r, c) {
                // Overlap is only legal at a matching letter (a crossing).
                if existing != chars[i] { return nil }
                intersections += 1
            } else {
                // This cell is newly written. Its perpendicular neighbors must be
                // empty, otherwise we'd create an unintended adjacent word.
                let perpA: (Int, Int), perpB: (Int, Int)
                switch orientation {
                case .horizontal:
                    perpA = (r - 1, c); perpB = (r + 1, c)
                case .vertical:
                    perpA = (r, c - 1); perpB = (r, c + 1)
                }
                if work.cell(perpA.0, perpA.1) != nil { return nil }
                if work.cell(perpB.0, perpB.1) != nil { return nil }
            }
        }

        // A valid placement must cross at least one existing word.
        guard intersections >= 1 else { return nil }
        return Candidate(start: start, orientation: orientation,
                         intersections: intersections, row: start.row, col: start.col)
    }

    /// Crop the working canvas to the used bounds and produce a 0-indexed layout.
    private static func crop(_ work: Working, unplaced: [String]) -> CrosswordLayout {
        guard !work.placed.isEmpty else {
            return CrosswordLayout(rows: 0, cols: 0, letters: [:], placed: [], unplaced: unplaced)
        }

        var minR = canvas, maxR = 0, minC = canvas, maxC = 0
        for r in 0..<canvas {
            for c in 0..<canvas where work.grid[r][c] != nil {
                minR = min(minR, r); maxR = max(maxR, r)
                minC = min(minC, c); maxC = max(maxC, c)
            }
        }
        guard minR <= maxR, minC <= maxC else {
            return CrosswordLayout(rows: 0, cols: 0, letters: [:], placed: [], unplaced: unplaced)
        }

        let rows = maxR - minR + 1
        let cols = maxC - minC + 1

        var letters: [GridCoord: Character] = [:]
        for r in minR...maxR {
            for c in minC...maxC {
                if let ch = work.grid[r][c] {
                    letters[GridCoord(row: r - minR, col: c - minC)] = ch
                }
            }
        }

        let placed = work.placed.map { p in
            PlacedWord(id: p.id, word: p.word,
                       start: GridCoord(row: p.start.row - minR, col: p.start.col - minC),
                       orientation: p.orientation)
        }

        return CrosswordLayout(rows: rows, cols: cols, letters: letters,
                               placed: placed, unplaced: unplaced)
    }
}

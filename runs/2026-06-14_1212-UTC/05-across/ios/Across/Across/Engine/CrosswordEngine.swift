import Foundation

/// Direction of a crossword slot.
enum Direction: String, Codable, CaseIterable {
    case across
    case down

    var opposite: Direction { self == .across ? .down : .across }

    var label: String { self == .across ? "Across" : "Down" }
}

/// A grid coordinate (row, col), both zero-based.
struct Coord: Hashable, Codable {
    let row: Int
    let col: Int
}

/// One across or down answer slot, derived from the grid.
struct Slot: Identifiable, Hashable {
    /// Stable identity: number + direction (e.g. "3-across").
    let number: Int
    let direction: Direction
    /// The cells this slot covers, in reading order (left→right or top→bottom).
    let cells: [Coord]
    /// The correct answer, derived from the solution grid (uppercase A–Z).
    let answer: String

    var id: String { "\(number)-\(direction.rawValue)" }
    var length: Int { cells.count }
}

/// Per-cell numbering / membership info.
struct CellInfo {
    let coord: Coord
    let isBlock: Bool
    /// The label shown in the corner (a number) if this cell starts a slot.
    let number: Int?
    /// The id of the across slot this cell belongs to, if any.
    let acrossSlotID: String?
    /// The id of the down slot this cell belongs to, if any.
    let downSlotID: String?
}

/// The immutable, parsed structure of one puzzle: cells, numbering, slots, and
/// cell↔slot maps. The engine derives EVERYTHING from the solution grid — there
/// is no hand-numbering. All indexing is guarded; ragged/invalid grids fail
/// validation rather than crash.
struct CrosswordEngine {
    let rows: Int
    let cols: Int
    /// Row-major solution letters; '#' marks a block.
    let solution: [[Character]]
    /// Per-cell info indexed [row][col].
    let cellInfo: [[CellInfo]]
    /// All slots keyed by id ("n-across" / "n-down").
    let slotsByID: [String: Slot]
    /// Across slots in numbering order.
    let acrossSlots: [Slot]
    /// Down slots in numbering order.
    let downSlots: [Slot]

    /// All non-block (fillable) coordinates.
    let fillableCoords: [Coord]

    /// Validate + parse a grid of solution strings. Returns nil if the grid is
    /// empty, ragged (non-rectangular), or contains characters other than '#'
    /// or A–Z, OR if any across/down run of length >= 2 contains a block (it
    /// cannot, by construction) — i.e. only well-formed grids are accepted.
    init?(grid rawGrid: [String]) {
        guard !rawGrid.isEmpty else { return nil }

        // Normalize to uppercase character rows.
        let charRows: [[Character]] = rawGrid.map { Array($0.uppercased()) }
        let width = charRows[0].count
        guard width > 0 else { return nil }

        // Rectangular check.
        for r in charRows where r.count != width {
            return nil
        }
        // Character whitelist: '#' or A–Z only.
        for r in charRows {
            for ch in r {
                if ch == "#" { continue }
                if ch >= "A" && ch <= "Z" { continue }
                return nil
            }
        }

        self.rows = charRows.count
        self.cols = width
        self.solution = charRows

        // Helpers (local, fully bounds-checked).
        let h = charRows.count
        let w = width
        func inBounds(_ r: Int, _ c: Int) -> Bool {
            r >= 0 && r < h && c >= 0 && c < w
        }
        func isBlock(_ r: Int, _ c: Int) -> Bool {
            guard inBounds(r, c) else { return true } // off-grid acts as a wall
            return charRows[r][c] == "#"
        }

        // --- Numbering + slot derivation (standard crossword rules) ---
        var numberAt = [[Int?]](repeating: [Int?](repeating: nil, count: w), count: h)
        var across: [Slot] = []
        var down: [Slot] = []
        var byID: [String: Slot] = [:]
        var acrossID = [[String?]](repeating: [String?](repeating: nil, count: w), count: h)
        var downID = [[String?]](repeating: [String?](repeating: nil, count: w), count: h)

        var nextNumber = 1
        for r in 0..<h {
            for c in 0..<w {
                guard !isBlock(r, c) else { continue }

                // A cell starts an across run if its left neighbor is a wall AND
                // its right neighbor is a fillable cell (run length >= 2).
                let startsAcross = isBlock(r, c - 1) && !isBlock(r, c + 1)
                // Similarly for down.
                let startsDown = isBlock(r - 1, c) && !isBlock(r + 1, c)

                guard startsAcross || startsDown else { continue }

                let number = nextNumber
                nextNumber += 1
                numberAt[r][c] = number

                if startsAcross {
                    var cells: [Coord] = []
                    var cc = c
                    while inBounds(r, cc) && !isBlock(r, cc) {
                        cells.append(Coord(row: r, col: cc))
                        cc += 1
                    }
                    let answer = String(cells.map { charRows[$0.row][$0.col] })
                    let slot = Slot(number: number, direction: .across, cells: cells, answer: answer)
                    across.append(slot)
                    byID[slot.id] = slot
                    for cell in cells { acrossID[cell.row][cell.col] = slot.id }
                }
                if startsDown {
                    var cells: [Coord] = []
                    var rr = r
                    while inBounds(rr, c) && !isBlock(rr, c) {
                        cells.append(Coord(row: rr, col: c))
                        rr += 1
                    }
                    let answer = String(cells.map { charRows[$0.row][$0.col] })
                    let slot = Slot(number: number, direction: .down, cells: cells, answer: answer)
                    down.append(slot)
                    byID[slot.id] = slot
                    for cell in cells { downID[cell.row][cell.col] = slot.id }
                }
            }
        }

        // Build per-cell info + fillable list.
        var info = [[CellInfo]]()
        var fillable: [Coord] = []
        for r in 0..<h {
            var rowInfo = [CellInfo]()
            for c in 0..<w {
                let block = charRows[r][c] == "#"
                if !block { fillable.append(Coord(row: r, col: c)) }
                rowInfo.append(CellInfo(coord: Coord(row: r, col: c),
                                        isBlock: block,
                                        number: numberAt[r][c],
                                        acrossSlotID: acrossID[r][c],
                                        downSlotID: downID[r][c]))
            }
            info.append(rowInfo)
        }

        self.cellInfo = info
        self.slotsByID = byID
        self.acrossSlots = across
        self.downSlots = down
        self.fillableCoords = fillable
    }

    /// Private memberwise initializer used only by `empty`.
    private init(rows: Int, cols: Int, solution: [[Character]], cellInfo: [[CellInfo]],
                 slotsByID: [String: Slot], acrossSlots: [Slot], downSlots: [Slot],
                 fillableCoords: [Coord]) {
        self.rows = rows
        self.cols = cols
        self.solution = solution
        self.cellInfo = cellInfo
        self.slotsByID = slotsByID
        self.acrossSlots = acrossSlots
        self.downSlots = downSlots
        self.fillableCoords = fillableCoords
    }

    /// A guaranteed-valid, empty 1×1 block engine used as a non-optional fallback
    /// when a puzzle's grid fails to parse. Never crashes; renders as a single block.
    static let empty: CrosswordEngine = {
        let info = CellInfo(coord: Coord(row: 0, col: 0), isBlock: true,
                            number: nil, acrossSlotID: nil, downSlotID: nil)
        return CrosswordEngine(rows: 1, cols: 1, solution: [["#"]], cellInfo: [[info]],
                               slotsByID: [:], acrossSlots: [], downSlots: [], fillableCoords: [])
    }()

    // MARK: - Lookups (all guarded)

    func info(at coord: Coord) -> CellInfo? {
        guard coord.row >= 0, coord.row < rows,
              coord.col >= 0, coord.col < cols else { return nil }
        return cellInfo[coord.row][coord.col]
    }

    func isBlock(at coord: Coord) -> Bool {
        info(at: coord)?.isBlock ?? true
    }

    func slot(id: String) -> Slot? { slotsByID[id] }

    /// The slot of the given direction that contains this cell, if any.
    func slot(at coord: Coord, direction: Direction) -> Slot? {
        guard let info = info(at: coord) else { return nil }
        let id = direction == .across ? info.acrossSlotID : info.downSlotID
        guard let id else { return nil }
        return slotsByID[id]
    }

    /// Solution letter at a coordinate ('#'/nil for blocks/out-of-range).
    func solutionLetter(at coord: Coord) -> Character? {
        guard let info = info(at: coord), !info.isBlock else { return nil }
        return solution[coord.row][coord.col]
    }

    /// All slots of a direction, in numbering order.
    func slots(_ direction: Direction) -> [Slot] {
        direction == .across ? acrossSlots : downSlots
    }

    // MARK: - Navigation

    /// Index of `slot` within its directional list, or nil.
    private func index(of slot: Slot) -> Int? {
        slots(slot.direction).firstIndex(where: { $0.id == slot.id })
    }

    /// The next slot after `slot` (wraps within direction, then crosses to the
    /// other direction's first slot). Returns nil only if there are no slots.
    func nextSlot(after slot: Slot) -> Slot? {
        let list = slots(slot.direction)
        guard let i = index(of: slot) else { return list.first }
        if i + 1 < list.count { return list[i + 1] }
        // Move to the other direction's first slot.
        let other = slots(slot.direction.opposite)
        return other.first ?? list.first
    }

    /// The previous slot before `slot` (mirror of nextSlot).
    func previousSlot(before slot: Slot) -> Slot? {
        let list = slots(slot.direction)
        guard let i = index(of: slot) else { return list.last }
        if i - 1 >= 0 { return list[i - 1] }
        let other = slots(slot.direction.opposite)
        return other.last ?? list.last
    }

    /// The first fillable cell of a slot (its starting square).
    func firstCell(of slot: Slot) -> Coord? { slot.cells.first }

    /// Within a slot, the next cell after `coord` (nil at end).
    func nextCell(in slot: Slot, after coord: Coord) -> Coord? {
        guard let i = slot.cells.firstIndex(of: coord) else { return nil }
        let n = i + 1
        return n < slot.cells.count ? slot.cells[n] : nil
    }

    /// Within a slot, the previous cell before `coord` (nil at start).
    func previousCell(in slot: Slot, before coord: Coord) -> Coord? {
        guard let i = slot.cells.firstIndex(of: coord) else { return nil }
        let p = i - 1
        return p >= 0 ? slot.cells[p] : nil
    }

    // MARK: - Checking against an entry grid

    /// Entry grid is row-major characters; '.' = empty, '#' = block, else a letter.
    func isCorrect(at coord: Coord, entry: [[Character]]) -> Bool {
        guard let sol = solutionLetter(at: coord),
              let entered = entryLetter(at: coord, entry: entry) else { return false }
        return sol == entered
    }

    /// Returns the entered letter (uppercased) or nil if empty/block/out of range.
    func entryLetter(at coord: Coord, entry: [[Character]]) -> Character? {
        guard coord.row >= 0, coord.row < entry.count,
              coord.col >= 0, coord.col < entry[coord.row].count else { return nil }
        let ch = entry[coord.row][coord.col]
        if ch == "." || ch == "#" { return nil }
        return Character(String(ch).uppercased())
    }

    /// True when every cell of the slot is filled correctly.
    func isSlotComplete(_ slot: Slot, entry: [[Character]]) -> Bool {
        for c in slot.cells where !isCorrect(at: c, entry: entry) { return false }
        return true
    }

    /// True when every fillable cell matches the solution.
    func isSolved(entry: [[Character]]) -> Bool {
        for c in fillableCoords where !isCorrect(at: c, entry: entry) { return false }
        return true
    }

    /// True when every fillable cell has SOME letter (not necessarily correct).
    func isFullyFilled(entry: [[Character]]) -> Bool {
        for c in fillableCoords where entryLetter(at: c, entry: entry) == nil { return false }
        return true
    }
}

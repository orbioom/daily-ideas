import SwiftUI
import SwiftData

/// Drives one solving session: holds the engine, the entered/revealed/checked
/// state, the current selection, and the timer. Persists progress to SwiftData
/// continuously. All grid access goes through the guarded engine.
@MainActor
final class BoardViewModel: ObservableObject {
    let puzzle: Puzzle
    let engine: CrosswordEngine

    /// Row-major entered letters: '.'=empty, '#'=block, else A–Z.
    @Published private(set) var entered: [[Character]]
    /// Revealed flags per cell (true = answer shown via Reveal).
    @Published private(set) var revealed: [[Bool]]
    /// Checked-incorrect flags per cell (set by Check; cleared on edit).
    @Published private(set) var wrong: [[Bool]]
    /// Checked-correct (locked) flags — once a Check confirms a cell, it stays marked.
    @Published private(set) var verified: [[Bool]]
    /// Tentative ("pencilled") flags — letters entered while Pencil mode is on,
    /// shown dimmed until confirmed by a Check.
    @Published private(set) var pencilled: [[Bool]]

    @Published var selected: Coord
    @Published var direction: Direction
    @Published private(set) var elapsedSeconds: Int
    @Published private(set) var isComplete: Bool
    @Published var usedCheck: Bool = false
    @Published var usedReveal: Bool = false
    /// Set true momentarily to trigger the win celebration.
    @Published var justSolved: Bool = false

    private var timerRunning = false
    private weak var settings: AppSettings?

    /// True when the puzzle's grid failed to parse; the view shows an error state.
    let isValid: Bool

    init(puzzle: Puzzle, progress: PuzzleProgress?, settings: AppSettings?) {
        self.puzzle = puzzle
        self.settings = settings
        // A malformed grid falls back to a minimal valid 1x1 engine so the view
        // can still construct; `isValid` drives the calm error state.
        if let engine = puzzle.makeEngine() {
            self.engine = engine
            self.isValid = true
        } else {
            self.engine = CrosswordEngine(grid: ["A"]) ?? CrosswordEngine.empty
            self.isValid = false
        }
        let engine = self.engine

        let rows = engine.rows, cols = engine.cols

        // Start from solution shape (blocks), empty fillable cells.
        var grid = [[Character]]()
        for r in 0..<rows {
            var row = [Character]()
            for c in 0..<cols {
                row.append(engine.cellInfo[r][c].isBlock ? "#" : ".")
            }
            grid.append(row)
        }
        var rev = [[Bool]](repeating: [Bool](repeating: false, count: cols), count: rows)
        var wr = [[Bool]](repeating: [Bool](repeating: false, count: cols), count: rows)
        var ver = [[Bool]](repeating: [Bool](repeating: false, count: cols), count: rows)

        // Restore saved progress, if any (guarded by length).
        if let progress {
            BoardViewModel.apply(progress.enteredLetters, into: &grid, rows: rows, cols: cols)
            let revChars = Array(progress.revealedMask)
            let chkChars = Array(progress.checkedMask)
            var idx = 0
            for r in 0..<rows {
                for c in 0..<cols {
                    if idx < revChars.count, revChars[idx] == "1" { rev[r][c] = true }
                    if idx < chkChars.count, chkChars[idx] == "1" { ver[r][c] = true }
                    idx += 1
                }
            }
            self.elapsedSeconds = max(0, progress.elapsedSeconds)
            self.isComplete = progress.completed
        } else {
            self.elapsedSeconds = 0
            self.isComplete = false
        }

        self.entered = grid
        self.revealed = rev
        self.wrong = wr
        self.verified = ver
        self.pencilled = [[Bool]](repeating: [Bool](repeating: false, count: cols), count: rows)

        // Initial selection: first fillable cell, prefer an across slot.
        let firstFill = engine.fillableCoords.first ?? Coord(row: 0, col: 0)
        self.selected = firstFill
        self.direction = engine.slot(at: firstFill, direction: .across) != nil ? .across : .down
    }

    /// Apply a row-major string into the grid, preserving '#'.
    private static func apply(_ s: String, into grid: inout [[Character]], rows: Int, cols: Int) {
        let chars = Array(s)
        var idx = 0
        for r in 0..<rows {
            for c in 0..<cols {
                guard idx < chars.count else { return }
                let ch = chars[idx]
                if grid[r][c] != "#" {
                    if ch == "." || ch == "#" {
                        grid[r][c] = "."
                    } else if ch >= "A" && ch <= "Z" {
                        grid[r][c] = ch
                    } else if ch >= "a" && ch <= "z" {
                        grid[r][c] = Character(String(ch).uppercased())
                    }
                }
                idx += 1
            }
        }
    }

    // MARK: - Derived

    var currentSlot: Slot? {
        engine.slot(at: selected, direction: direction)
    }

    func info(_ coord: Coord) -> CellInfo? { engine.info(at: coord) }

    func letter(at coord: Coord) -> Character? {
        guard coord.row >= 0, coord.row < entered.count,
              coord.col >= 0, coord.col < entered[coord.row].count else { return nil }
        let ch = entered[coord.row][coord.col]
        return (ch == "." || ch == "#") ? nil : ch
    }

    func isRevealed(_ coord: Coord) -> Bool {
        guard inRange(coord) else { return false }
        return revealed[coord.row][coord.col]
    }
    func isWrong(_ coord: Coord) -> Bool {
        guard inRange(coord) else { return false }
        return wrong[coord.row][coord.col]
    }
    func isVerified(_ coord: Coord) -> Bool {
        guard inRange(coord) else { return false }
        return verified[coord.row][coord.col]
    }
    func isPencilled(_ coord: Coord) -> Bool {
        guard inRange(coord) else { return false }
        return pencilled[coord.row][coord.col]
    }

    /// Whether a coord is part of the current slot.
    func inCurrentSlot(_ coord: Coord) -> Bool {
        currentSlot?.cells.contains(coord) ?? false
    }

    private func inRange(_ coord: Coord) -> Bool {
        coord.row >= 0 && coord.row < entered.count &&
        coord.col >= 0 && coord.col < entered[coord.row].count
    }

    /// The clue for the current slot.
    var currentClue: String {
        guard let slot = currentSlot else { return "" }
        return puzzle.clue(for: slot)
    }

    // MARK: - Selection

    /// Tap a cell: select it, or toggle direction if re-tapping the same cell.
    func selectCell(_ coord: Coord) {
        guard let info = engine.info(at: coord), !info.isBlock else { return }
        if coord == selected {
            // Toggle direction if a slot exists in the other direction.
            if engine.slot(at: coord, direction: direction.opposite) != nil {
                direction = direction.opposite
            }
        } else {
            selected = coord
            // Prefer keeping direction; fall back to whichever slot exists.
            if engine.slot(at: coord, direction: direction) == nil {
                direction = direction.opposite
            }
        }
        haptic(.tap)
    }

    func toggleDirection() {
        if engine.slot(at: selected, direction: direction.opposite) != nil {
            direction = direction.opposite
            haptic(.tap)
        }
    }

    func moveToSlot(_ slot: Slot) {
        direction = slot.direction
        if let first = firstUnfilledCell(of: slot) ?? slot.cells.first {
            selected = first
        }
    }

    func nextClue() {
        guard let slot = currentSlot else { return }
        var candidate = engine.nextSlot(after: slot)
        if settings?.skipFilled == true {
            // Skip slots already fully filled (loop guard with a max count).
            var guardCount = 0
            while let s = candidate, isSlotFilled(s), guardCount < engine.acrossSlots.count + engine.downSlots.count {
                candidate = engine.nextSlot(after: s)
                guardCount += 1
                if let c = candidate, c.id == slot.id { break }
            }
        }
        if let target = candidate { moveToSlot(target) }
        haptic(.tap)
    }

    func previousClue() {
        guard let slot = currentSlot else { return }
        if let target = engine.previousSlot(before: slot) {
            moveToSlot(target)
        }
        haptic(.tap)
    }

    // MARK: - Entry

    func type(_ raw: Character) {
        guard let ch = sanitize(raw) else { return }
        guard inRange(selected), entered[selected.row][selected.col] != "#" else { return }
        // Don't overwrite a verified/locked-correct cell.
        if verified[selected.row][selected.col] { advanceWithinSlot(); return }
        entered[selected.row][selected.col] = ch
        wrong[selected.row][selected.col] = false
        revealed[selected.row][selected.col] = false
        pencilled[selected.row][selected.col] = (settings?.pencilMode == true)
        haptic(.tap)
        startTimerIfNeeded()
        if settings?.autoAdvance == true {
            advanceWithinSlot()
        }
        evaluateCompletion()
    }

    func deleteBackward() {
        guard inRange(selected) else { return }
        let cur = entered[selected.row][selected.col]
        if cur != "." && cur != "#" && !verified[selected.row][selected.col] {
            // Clear the current cell.
            entered[selected.row][selected.col] = "."
            wrong[selected.row][selected.col] = false
            pencilled[selected.row][selected.col] = false
        } else {
            // Move back one and clear that.
            if let slot = currentSlot, let prev = engine.previousCell(in: slot, before: selected) {
                selected = prev
                if !verified[prev.row][prev.col] {
                    entered[prev.row][prev.col] = "."
                    wrong[prev.row][prev.col] = false
                    pencilled[prev.row][prev.col] = false
                }
            }
        }
        haptic(.tap)
        isComplete = engine.isSolved(entry: entered)
    }

    private func advanceWithinSlot() {
        guard let slot = currentSlot else { return }
        // Move to the next cell; prefer next *empty* cell in the slot.
        if let next = nextEmptyCell(in: slot, after: selected) {
            selected = next
        } else if let next = engine.nextCell(in: slot, after: selected) {
            selected = next
        }
        // If the slot is full and auto-advance, jump to the next clue.
        else if settings?.autoAdvance == true {
            nextClue()
        }
    }

    private func nextEmptyCell(in slot: Slot, after coord: Coord) -> Coord? {
        guard let i = slot.cells.firstIndex(of: coord) else { return nil }
        var j = i + 1
        while j < slot.cells.count {
            let c = slot.cells[j]
            if letter(at: c) == nil { return c }
            j += 1
        }
        return nil
    }

    private func firstUnfilledCell(of slot: Slot) -> Coord? {
        slot.cells.first(where: { letter(at: $0) == nil })
    }

    func isSlotFilled(_ slot: Slot) -> Bool {
        slot.cells.allSatisfy { letter(at: $0) != nil }
    }

    // MARK: - Check / Reveal

    /// Check a single cell. Marks wrong if incorrect, verified if correct.
    func checkCell(_ coord: Coord) {
        usedCheck = true
        applyCheck(at: coord)
        haptic(.tap)
    }

    func checkCurrentSlot() {
        usedCheck = true
        guard let slot = currentSlot else { return }
        for c in slot.cells { applyCheck(at: c) }
        haptic(.tap)
    }

    func checkPuzzle() {
        usedCheck = true
        for c in engine.fillableCoords { applyCheck(at: c) }
        haptic(.tap)
    }

    private func applyCheck(at coord: Coord) {
        guard inRange(coord), entered[coord.row][coord.col] != "#" else { return }
        guard let entry = letter(at: coord) else { return }   // only check filled cells
        if let sol = engine.solutionLetter(at: coord), sol == entry {
            verified[coord.row][coord.col] = true
            wrong[coord.row][coord.col] = false
            pencilled[coord.row][coord.col] = false   // confirmed: no longer tentative
        } else {
            wrong[coord.row][coord.col] = true
        }
    }

    func revealCell(_ coord: Coord) {
        usedReveal = true
        applyReveal(at: coord)
        haptic(.select)
        evaluateCompletion()
    }

    func revealCurrentSlot() {
        usedReveal = true
        guard let slot = currentSlot else { return }
        for c in slot.cells { applyReveal(at: c) }
        haptic(.select)
        evaluateCompletion()
    }

    func revealPuzzle() {
        usedReveal = true
        for c in engine.fillableCoords { applyReveal(at: c) }
        haptic(.select)
        evaluateCompletion()
    }

    private func applyReveal(at coord: Coord) {
        guard inRange(coord), entered[coord.row][coord.col] != "#" else { return }
        guard let sol = engine.solutionLetter(at: coord) else { return }
        entered[coord.row][coord.col] = sol
        revealed[coord.row][coord.col] = true
        verified[coord.row][coord.col] = true
        wrong[coord.row][coord.col] = false
        pencilled[coord.row][coord.col] = false
    }

    // MARK: - Completion

    private func evaluateCompletion() {
        let solved = engine.isSolved(entry: entered)
        if solved && !isComplete {
            isComplete = true
            justSolved = true
            stopTimer()
            haptic(.success)
        } else {
            isComplete = solved
        }
    }

    // MARK: - Timer (pause-safe)

    func startTimerIfNeeded() {
        guard !isComplete else { return }
        timerRunning = true
    }

    func pause() { timerRunning = false }

    func resume() {
        guard !isComplete else { return }
        timerRunning = true
    }

    /// Called once per second by the view's timer publisher.
    func tick() {
        guard timerRunning, !isComplete else { return }
        elapsedSeconds += 1
    }

    private func stopTimer() { timerRunning = false }

    // MARK: - Persistence

    /// Encode entered letters as a row-major string.
    func encodedEntered() -> String {
        var out = ""
        for row in entered { out.append(String(row)) }
        return out
    }

    func encodedRevealed() -> String {
        encodeMask(revealed)
    }

    func encodedChecked() -> String {
        encodeMask(verified)
    }

    private func encodeMask(_ mask: [[Bool]]) -> String {
        var out = ""
        for r in 0..<entered.count {
            for c in 0..<entered[r].count {
                if entered[r][c] == "#" { out.append("#") }
                else { out.append(mask[r][c] ? "1" : "0") }
            }
        }
        return out
    }

    // MARK: - Helpers

    private func sanitize(_ ch: Character) -> Character? {
        let up = Character(String(ch).uppercased())
        if up >= "A" && up <= "Z" { return up }
        return nil
    }

    private enum Feedback { case tap, select, success }
    private func haptic(_ f: Feedback) {
        guard let on = settings?.hapticsEnabled, on else { return }
        switch f {
        case .tap: Haptics.tap(true)
        case .select: Haptics.select(true)
        case .success: Haptics.success(true)
        }
    }
}

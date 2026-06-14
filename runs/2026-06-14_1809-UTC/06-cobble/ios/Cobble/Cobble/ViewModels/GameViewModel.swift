import SwiftUI
import SwiftData

/// Drives a playable board (classic or daily). Owned by the play screen as a @StateObject.
/// A final ObservableObject (per conventions) with @Published state. Tap-to-place is the
/// required path: select a tray piece, preview a ghost on the board, tap a valid cell to
/// commit. Fully crash-proof — every grid access is bounds-checked in BlockEngine.
@MainActor
final class GameViewModel: ObservableObject {

    enum Phase: Equatable {
        case playing
        case gameOver
    }

    // MARK: - Published state
    @Published private(set) var grid: [[Int]] = BlockEngine.emptyGrid()
    /// The three tray slots. A `nil` slot was already placed this batch.
    @Published private(set) var tray: [Piece?] = [nil, nil, nil]
    @Published private(set) var score: Int = 0
    @Published private(set) var combo: Int = 0
    @Published private(set) var longestCombo: Int = 0
    @Published private(set) var linesCleared: Int = 0
    @Published private(set) var piecesPlaced: Int = 0
    @Published private(set) var phase: Phase = .playing
    @Published private(set) var undosUsed: Int = 0

    /// Index into `tray` of the currently selected piece (nil = none selected).
    @Published var selectedSlot: Int? = nil
    /// The anchor under the user's finger for the ghost preview (nil = no preview).
    @Published var ghostAnchor: Coord? = nil
    /// Cells that just cleared, for a brief flash animation.
    @Published private(set) var flashingCells: Set<Coord> = []
    /// A transient combo banner string (e.g. "Combo ×3!").
    @Published private(set) var comboBanner: String? = nil

    // MARK: - Config
    private(set) var mode: GameMode = .classic
    private(set) var dateKey: String = ""
    private(set) var startedAt = Date()

    // MARK: - Collaborators
    private weak var context: ModelContext?
    private var settings: AppSettings?
    private var isPro: Bool = false
    private var colorCount: Int = PieceLibrary.paletteColorCount
    private var dealer = PieceDealer(seed: 1)
    private var saved: SavedGame?

    /// Undo history: snapshots of full state before each placement (small, bounded).
    private struct Snapshot {
        let grid: [[Int]]
        let tray: [Piece?]
        let score: Int
        let combo: Int
        let longestCombo: Int
        let linesCleared: Int
        let piecesPlaced: Int
    }
    private var history: [Snapshot] = []
    private let historyCap = 12

    var canUndo: Bool { !history.isEmpty && phase == .playing }
    var hasUndoBudget: Bool { Pro.canUndo(used: undosUsed, isPro: isPro) }
    var remainingUndos: Int? { Pro.remainingUndos(used: undosUsed, isPro: isPro) }

    // MARK: - Lifecycle

    func configure(context: ModelContext, settings: AppSettings, isPro: Bool) {
        self.context = context
        self.settings = settings
        self.isPro = isPro
        self.colorCount = max(1, settings.palette(isPro: isPro).count)
    }

    /// Start (or restart) a game. For daily, seed from the date; for classic, seed from
    /// the clock so each new game differs.
    func startNew(mode: GameMode, dateKey: String = "") {
        self.mode = mode
        self.dateKey = mode == .daily ? (dateKey.isEmpty ? DailySeed.dateKey(for: Date()) : dateKey) : ""
        let seed: UInt64
        if mode == .daily {
            seed = seedForDaily(self.dateKey)
        } else {
            seed = UInt64(bitPattern: Int64(Date().timeIntervalSince1970 * 1000)) ^ 0xD1B54A32D192ED03
        }
        dealer = PieceDealer(seed: seed)
        grid = BlockEngine.emptyGrid()
        score = 0; combo = 0; longestCombo = 0; linesCleared = 0; piecesPlaced = 0
        undosUsed = 0
        history.removeAll()
        selectedSlot = nil; ghostAnchor = nil; flashingCells = []; comboBanner = nil
        phase = .playing
        startedAt = Date()
        tray = dealer.dealNext(colorCount: colorCount)
        if mode == .classic { persistClassic() }
        checkGameOver()
    }

    private func seedForDaily(_ key: String) -> UInt64 {
        // Derive a stable seed from the yyyyMMdd key digits.
        UInt64(key) ?? 20260101
    }

    /// Resume a persisted classic game. Returns false if the save was corrupt/empty.
    @discardableResult
    func resumeClassic(_ game: SavedGame) -> Bool {
        guard let g = GameCodec.decodeGrid(game.gridBlob),
              let pieces = GameCodec.decodePieces(game.piecesBlob),
              pieces.count == 3 else {
            return false
        }
        saved = game
        mode = .classic
        dateKey = ""
        grid = g
        tray = pieces
        score = game.score
        combo = game.combo
        longestCombo = game.longestCombo
        linesCleared = game.linesCleared
        piecesPlaced = game.piecesPlaced
        undosUsed = 0
        dealer = PieceDealer(seed: game.seed, batchesDealt: game.batchesDealt)
        history.removeAll()
        selectedSlot = nil; ghostAnchor = nil; flashingCells = []; comboBanner = nil
        phase = .playing
        startedAt = Date()
        colorCount = max(1, settings?.palette(isPro: isPro).count ?? PieceLibrary.paletteColorCount)
        checkGameOver()
        return true
    }

    // MARK: - Selection & ghost preview

    func select(slot: Int) {
        guard tray.indices.contains(slot), tray[slot] != nil, phase == .playing else { return }
        if selectedSlot == slot {
            selectedSlot = nil
            ghostAnchor = nil
        } else {
            selectedSlot = slot
            Haptics.select(settings?.hapticsEnabled ?? false)
        }
    }

    /// The piece currently selected, if any.
    var selectedPiece: Piece? {
        guard let s = selectedSlot, tray.indices.contains(s) else { return nil }
        return tray[s]
    }

    /// Compute a clamped anchor so the piece's bounding box sits in-bounds under the
    /// targeted cell. Used by the board to draw the ghost.
    func anchor(forTargetRow row: Int, col: Int) -> Coord? {
        guard let piece = selectedPiece else { return nil }
        let maxRow = BlockEngine.size - piece.height
        let maxCol = BlockEngine.size - piece.width
        let r = min(max(row, 0), max(maxRow, 0))
        let c = min(max(col, 0), max(maxCol, 0))
        return Coord(row: r, col: c)
    }

    /// Update the ghost preview anchor from a targeted cell (during press/drag).
    func updateGhost(targetRow: Int, col: Int) {
        guard phase == .playing, selectedPiece != nil else { return }
        ghostAnchor = anchor(forTargetRow: targetRow, col: col)
    }

    func clearGhost() { ghostAnchor = nil }

    /// True if the selected piece can legally be placed at `anchor`.
    func ghostIsValid(_ anchor: Coord) -> Bool {
        guard let piece = selectedPiece else { return false }
        return BlockEngine.canPlace(piece, atAnchor: anchor, grid: grid)
    }

    /// The set of board cells the ghost currently occupies (for highlighting).
    func ghostCells() -> Set<Coord> {
        guard let piece = selectedPiece, let anchor = ghostAnchor else { return [] }
        var set = Set<Coord>()
        for cell in piece.cells {
            let coord = Coord(row: anchor.row + cell.row, col: anchor.col + cell.col)
            if BlockEngine.inBounds(coord.row, coord.col) { set.insert(coord) }
        }
        return set
    }

    // MARK: - Commit a placement (tap-to-place)

    /// Attempt to place the selected piece at the targeted cell. Returns true on success.
    @discardableResult
    func commit(targetRow row: Int, col: Int) -> Bool {
        guard phase == .playing, let slot = selectedSlot,
              tray.indices.contains(slot), let piece = tray[slot] else { return false }
        guard let anchor = anchor(forTargetRow: row, col: col),
              BlockEngine.canPlace(piece, atAnchor: anchor, grid: grid) else {
            Haptics.invalid(settings?.hapticsEnabled ?? false)
            return false
        }

        pushHistory()

        let result = BlockEngine.place(piece, atAnchor: anchor, grid: grid)
        let clearedAny = result.linesCleared > 0

        // Combo: increment on a clearing placement, reset otherwise.
        let newCombo = clearedAny ? combo + 1 : 0
        let gained = BlockEngine.points(for: result, comboAfter: max(newCombo, 1))

        grid = result.grid
        tray[slot] = nil
        score += gained
        combo = newCombo
        longestCombo = max(longestCombo, newCombo)
        linesCleared += result.linesCleared
        piecesPlaced += 1
        selectedSlot = nil
        ghostAnchor = nil

        // Feedback.
        let haptics = settings?.hapticsEnabled ?? false
        if clearedAny {
            Haptics.clear(haptics)
            SoundPlayer.shared.play(.clear, enabled: settings?.soundEnabled ?? false)
            flashClearedCells(rows: result.clearedRows, cols: result.clearedCols)
            if newCombo >= 2 {
                comboBanner = "Combo ×\(newCombo)!"
            }
        } else {
            Haptics.place(haptics)
            SoundPlayer.shared.play(.place, enabled: settings?.soundEnabled ?? false)
        }

        // Refill the tray when all three are used.
        if tray.allSatisfy({ $0 == nil }) {
            tray = dealer.dealNext(colorCount: colorCount)
        }

        if mode == .classic { persistClassic() }
        checkGameOver()
        return true
    }

    private func flashClearedCells(rows: [Int], cols: [Int]) {
        var set = Set<Coord>()
        for r in rows where BlockEngine.range.contains(r) {
            for c in BlockEngine.range { set.insert(Coord(row: r, col: c)) }
        }
        for c in cols where BlockEngine.range.contains(c) {
            for r in BlockEngine.range { set.insert(Coord(row: r, col: c)) }
        }
        flashingCells = set
    }

    /// Called by the view after the flash animation window to reset transient banners.
    func clearTransients() {
        flashingCells = []
        comboBanner = nil
    }

    // MARK: - Undo

    private func pushHistory() {
        let snap = Snapshot(grid: grid, tray: tray, score: score, combo: combo,
                            longestCombo: longestCombo, linesCleared: linesCleared,
                            piecesPlaced: piecesPlaced)
        history.append(snap)
        if history.count > historyCap { history.removeFirst(history.count - historyCap) }
    }

    /// Revert the last placement if there is budget. Returns true on success.
    @discardableResult
    func undo() -> Bool {
        guard phase == .playing, hasUndoBudget, let snap = history.popLast() else { return false }
        grid = snap.grid
        tray = snap.tray
        score = snap.score
        combo = snap.combo
        longestCombo = snap.longestCombo
        linesCleared = snap.linesCleared
        piecesPlaced = snap.piecesPlaced
        undosUsed += 1
        selectedSlot = nil
        ghostAnchor = nil
        flashingCells = []
        comboBanner = nil
        Haptics.select(settings?.hapticsEnabled ?? false)
        if mode == .classic { persistClassic() }
        return true
    }

    // MARK: - Game over

    private func checkGameOver() {
        let available = tray.compactMap { $0 }
        if BlockEngine.isGameOver(pieces: available, grid: grid) {
            phase = .gameOver
            selectedSlot = nil
            ghostAnchor = nil
            Haptics.gameOver(settings?.hapticsEnabled ?? false)
            SoundPlayer.shared.play(.gameOver, enabled: settings?.soundEnabled ?? false)
            recordResult()
            if mode == .classic { clearSavedGame() }
        }
    }

    private func recordResult() {
        guard let context else { return }
        let result = GameResult(date: Date(),
                                score: score,
                                linesCleared: linesCleared,
                                piecesPlaced: piecesPlaced,
                                longestCombo: longestCombo,
                                mode: mode,
                                durationSec: Int(Date().timeIntervalSince(startedAt)),
                                dateKey: dateKey)
        context.insert(result)
        try? context.save()
        BestScores.record(score: score, mode: mode, dateKey: dateKey)
    }

    // MARK: - Persistence (classic resume)

    private func persistClassic() {
        guard mode == .classic, let context else { return }
        let blobGrid = GameCodec.encodeGrid(grid)
        let blobPieces = GameCodec.encodePieces(tray)
        if let saved {
            saved.gridBlob = blobGrid
            saved.piecesBlob = blobPieces
            saved.score = score
            saved.combo = combo
            saved.longestCombo = longestCombo
            saved.linesCleared = linesCleared
            saved.piecesPlaced = piecesPlaced
            saved.seed = dealer.seed
            saved.batchesDealt = dealer.batchesDealt
            saved.updatedAt = Date()
        } else {
            let game = SavedGame(gridBlob: blobGrid,
                                 piecesBlob: blobPieces,
                                 score: score,
                                 combo: combo,
                                 longestCombo: longestCombo,
                                 linesCleared: linesCleared,
                                 piecesPlaced: piecesPlaced,
                                 seed: dealer.seed,
                                 batchesDealt: dealer.batchesDealt,
                                 mode: .classic)
            context.insert(game)
            saved = game
        }
        try? context.save()
    }

    private func clearSavedGame() {
        guard let context, let saved else { return }
        context.delete(saved)
        try? context.save()
        self.saved = nil
    }
}

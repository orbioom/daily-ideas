import SwiftUI
import SwiftData

/// One tile shown on the board, with a stable identity so SwiftUI can animate
/// spawns, slides and merges. Position is (row, col); value is the power of two.
struct BoardTile: Identifiable, Equatable {
    let id: UUID
    var value: Int
    var row: Int
    var col: Int
}

/// The 2048 win target.
let kWinTarget = 2048

/// Drives a single live game: grid, score, undo, timing, persistence, and the
/// win / continue / game-over flags. Pure board math lives in `BoardEngine`.
@MainActor
final class GameViewModel: ObservableObject {
    // MARK: Published game state
    @Published private(set) var grid: [[Int]]
    @Published private(set) var score: Int = 0
    @Published private(set) var best: Int = 0
    @Published private(set) var moves: Int = 0
    @Published private(set) var boardSize: Int
    @Published private(set) var elapsedSeconds: Int = 0
    @Published private(set) var mode: GameMode = .classic

    /// Stable per-cell tile identities, indexed [row][col]; nil = empty cell.
    @Published private(set) var tileIDs: [[UUID?]]

    @Published private(set) var hasWon = false          // crossed 2048 this game
    @Published var continuedAfterWin = false            // chose "keep going"
    @Published private(set) var isGameOver = false
    @Published var showWinOverlay = false
    @Published private(set) var lastMergeCount = 0      // for haptic intensity

    /// Undo stack of prior snapshots (capped). Empty = nothing to undo.
    private var undoStack: [Snapshot] = []
    private let maxUndo = 20
    /// Undos already spent this game (for the free-tier limit).
    @Published private(set) var undosUsedThisGame = 0

    private var seed: Int = 0
    private var rng: SplitMix64
    private var startedAt = Date()
    private var recordWritten = false

    // MARK: Dependencies
    private weak var modelContext: ModelContext?

    private struct Snapshot {
        let grid: [[Int]]
        let score: Int
        let moves: Int
        let tileIDs: [[UUID?]]
    }

    // MARK: Init
    init(boardSize: Int) {
        let s = max(2, min(8, boardSize))
        self.boardSize = s
        self.grid = Array(repeating: Array(repeating: 0, count: s), count: s)
        self.tileIDs = Array(repeating: Array(repeating: nil, count: s), count: s)
        self.rng = SplitMix64(seed: UInt64(bitPattern: Int64(Date().timeIntervalSince1970.bitPattern)))
    }

    var canUndo: Bool { !undoStack.isEmpty }

    /// Tiles for rendering, derived from grid + stable IDs.
    var tiles: [BoardTile] {
        var out: [BoardTile] = []
        for r in 0..<boardSize where r < grid.count {
            for c in 0..<boardSize where c < grid[r].count {
                let v = grid[r][c]
                guard v != 0 else { continue }
                let id = (r < tileIDs.count && c < tileIDs[r].count ? tileIDs[r][c] : nil) ?? UUID()
                out.append(BoardTile(id: id, value: v, row: r, col: c))
            }
        }
        return out
    }

    // MARK: Wiring

    func attach(context: ModelContext) {
        modelContext = context
    }

    /// Loads the saved game for `size`, or starts a fresh one if none exists.
    func loadOrStart(size: Int, context: ModelContext) {
        attach(context: context)
        let s = max(2, min(8, size))
        if let saved = fetchSaved(size: s) {
            adopt(saved)
        } else {
            startNewGame(size: s, mode: .classic, seed: nil)
        }
    }

    private func fetchSaved(size: Int) -> SavedGame? {
        guard let context = modelContext else { return nil }
        let descriptor = FetchDescriptor<SavedGame>(predicate: #Predicate { $0.boardSize == size })
        return (try? context.fetch(descriptor))?.first
    }

    private func adopt(_ saved: SavedGame) {
        boardSize = max(2, min(8, saved.boardSize))
        let engine = BoardEngine(size: boardSize, grid: saved.grid)
        grid = engine.grid
        score = max(0, saved.score)
        best = max(saved.best, score)
        moves = max(0, saved.moves)
        seed = saved.seed
        elapsedSeconds = max(0, saved.elapsedSeconds)
        mode = saved.mode
        continuedAfterWin = saved.continuedAfterWin
        startedAt = saved.startedAt
        rebuildTileIDs()
        undoStack.removeAll()
        undosUsedThisGame = 0
        recordWritten = false
        hasWon = engine.hasReached(kWinTarget)
        isGameOver = engine.isGameOver()
        showWinOverlay = false
        // If the board is empty (fresh saved record), seed two starting tiles.
        if engine.emptyCells.count == boardSize * boardSize {
            spawnStartingTiles()
        }
    }

    /// Assigns fresh IDs to every occupied cell (used when adopting a saved grid).
    private func rebuildTileIDs() {
        var ids = Array(repeating: Array(repeating: UUID?.none, count: boardSize), count: boardSize)
        for r in 0..<boardSize where r < grid.count {
            for c in 0..<boardSize where c < grid[r].count where grid[r][c] != 0 {
                ids[r][c] = UUID()
            }
        }
        tileIDs = ids
    }

    // MARK: New game

    /// Starts a brand-new game. `seed != nil` indicates a daily challenge.
    func startNewGame(size: Int, mode: GameMode, seed seedValue: Int?) {
        let s = max(2, min(8, size))
        // Carry over the best for this size from the prior session/saved record.
        let priorBest = max(best, fetchSaved(size: s)?.best ?? 0)
        boardSize = s
        grid = Array(repeating: Array(repeating: 0, count: s), count: s)
        tileIDs = Array(repeating: Array(repeating: nil, count: s), count: s)
        score = 0
        moves = 0
        elapsedSeconds = 0
        self.mode = mode
        hasWon = false
        continuedAfterWin = false
        isGameOver = false
        showWinOverlay = false
        undoStack.removeAll()
        undosUsedThisGame = 0
        recordWritten = false
        startedAt = Date()
        best = priorBest

        if let seedValue {
            seed = seedValue
            rng = SplitMix64(seed: UInt64(bitPattern: Int64(seedValue)))
        } else {
            seed = 0
            rng = SplitMix64(seed: UInt64(bitPattern: Int64(Date().timeIntervalSince1970.bitPattern)) ^ UInt64(Int.random(in: 0...Int(Int32.max))))
        }
        spawnStartingTiles()
        persist()
    }

    private func spawnStartingTiles() {
        spawnTile()
        spawnTile()
    }

    /// Spawns one tile into a random empty cell using the current RNG, assigning a new ID.
    private func spawnTile() {
        var engine = BoardEngine(size: boardSize, grid: grid)
        let cellsBefore = Set(engine.emptyCells.map { "\($0.row),\($0.col)" })
        guard engine.spawnTile(using: &rng) != nil else { return }
        grid = engine.grid
        // Find the newly filled cell to assign its ID.
        for r in 0..<boardSize {
            for c in 0..<boardSize where grid[r][c] != 0 {
                let key = "\(r),\(c)"
                if cellsBefore.contains(key), (r >= tileIDs.count || c >= tileIDs[r].count || tileIDs[r][c] == nil) {
                    setTileID(UUID(), row: r, col: c)
                }
            }
        }
    }

    private func setTileID(_ id: UUID?, row: Int, col: Int) {
        guard row >= 0, row < tileIDs.count, col >= 0, col < tileIDs[row].count else { return }
        tileIDs[row][col] = id
    }

    // MARK: Move

    /// Applies a swipe. Returns whether anything moved (drives the haptic).
    @discardableResult
    func handle(_ direction: Direction) -> MoveResult {
        guard !isGameOver else {
            return MoveResult(grid: grid, gained: 0, moved: false, merges: 0)
        }
        let engine = BoardEngine(size: boardSize, grid: grid)
        let result = engine.move(direction)
        guard result.moved else {
            lastMergeCount = 0
            return result
        }

        // Snapshot for undo BEFORE mutating.
        pushUndo()

        grid = result.grid
        score += result.gained
        best = max(best, score)
        moves += 1
        lastMergeCount = result.merges
        // After a structural move, tile identities can't be tracked cell-to-cell
        // reliably, so reassign fresh IDs for the new layout (animations still fade/slide).
        rebuildTileIDs()

        // Spawn a new tile.
        spawnTile()

        // Win check.
        let post = BoardEngine(size: boardSize, grid: grid)
        if !hasWon, post.hasReached(kWinTarget) {
            hasWon = true
            if !continuedAfterWin { showWinOverlay = true }
        }
        // Game-over check.
        if post.isGameOver() {
            isGameOver = true
            writeRecord(won: hasWon)
        }
        persist()
        return result
    }

    private func pushUndo() {
        undoStack.append(Snapshot(grid: grid, score: score, moves: moves, tileIDs: tileIDs))
        if undoStack.count > maxUndo {
            undoStack.removeFirst(undoStack.count - maxUndo)
        }
    }

    /// Reverts the last move. `unlimited` is true for Pro (bypasses the free counter).
    /// Returns true if an undo happened.
    @discardableResult
    func undo(unlimited: Bool) -> Bool {
        guard let snap = undoStack.popLast() else { return false }
        if !unlimited, undosUsedThisGame >= Pro.freeUndosPerGame {
            // Put it back; caller should have shown a paywall instead.
            undoStack.append(snap)
            return false
        }
        grid = snap.grid
        score = snap.score
        moves = snap.moves
        tileIDs = snap.tileIDs
        undosUsedThisGame += 1
        isGameOver = false
        // Re-evaluate win flag for the restored grid (don't re-show overlay).
        let engine = BoardEngine(size: boardSize, grid: grid)
        hasWon = engine.hasReached(kWinTarget)
        persist()
        return true
    }

    /// Whether a free player still has undos available this game.
    func hasFreeUndo(isPro: Bool) -> Bool {
        isPro || undosUsedThisGame < Pro.freeUndosPerGame
    }

    func remainingFreeUndos(isPro: Bool) -> Int {
        isPro ? Int.max : max(0, Pro.freeUndosPerGame - undosUsedThisGame)
    }

    // MARK: Win / continue

    func continuePlaying() {
        continuedAfterWin = true
        showWinOverlay = false
        persist()
    }

    // MARK: Timer

    /// Called once per second by the view's timer while a game is active.
    func tick() {
        guard !isGameOver, hasActiveTiles else { return }
        elapsedSeconds += 1
        // Persist time roughly every 5s to avoid excess writes.
        if elapsedSeconds % 5 == 0 { persist() }
    }

    private var hasActiveTiles: Bool {
        for row in grid { for v in row where v != 0 { return true } }
        return false
    }

    // MARK: Persistence

    /// Writes the current state to the single SavedGame for this board size.
    func persist() {
        guard let context = modelContext else { return }
        let s = boardSize
        if let existing = fetchSaved(size: s) {
            existing.grid = grid
            existing.score = score
            existing.best = best
            existing.moves = moves
            existing.seed = seed
            existing.elapsedSeconds = elapsedSeconds
            existing.continuedAfterWin = continuedAfterWin
            existing.modeRaw = mode.rawValue
            existing.startedAt = startedAt
        } else {
            let saved = SavedGame(boardSize: s, grid: grid, score: score, best: best,
                                  moves: moves, seed: seed, startedAt: startedAt,
                                  elapsedSeconds: elapsedSeconds,
                                  continuedAfterWin: continuedAfterWin, mode: mode)
            context.insert(saved)
        }
        try? context.save()
    }

    /// Writes a GameRecord exactly once when a game ends (over or won).
    private func writeRecord(won: Bool) {
        guard !recordWritten, let context = modelContext else { return }
        recordWritten = true
        let highest = BoardEngine(size: boardSize, grid: grid).highestTile
        let record = GameRecord(date: Date(), boardSize: boardSize, score: score,
                                highestTile: highest, won: won, moves: moves,
                                durationSeconds: elapsedSeconds, mode: mode)
        context.insert(record)
        try? context.save()
    }

    var isInProgress: Bool {
        hasActiveTiles && moves > 0 && !isGameOver
    }
}

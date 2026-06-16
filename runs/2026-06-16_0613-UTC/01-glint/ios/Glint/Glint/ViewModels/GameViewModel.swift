import SwiftUI
import SwiftData

/// Drives a single play session: holds the live board, applies player swaps via the
/// engine, animates resolve steps, tracks goal progress, and detects win/lose.
@MainActor
@Observable
final class GameViewModel {
    // Configuration
    let mode: GameMode
    let level: Level?
    let rows: Int
    let cols: Int
    let moveLimit: Int?          // nil = endless (Zen)
    let goal: GoalType?

    // Live state
    private(set) var board: Board
    private(set) var rng: SplitMix64
    private let engine = MatchEngine(colorCount: 6)

    private(set) var score = 0
    private(set) var movesUsed = 0
    private(set) var clearedByColor: [GemColor: Int] = [:]
    private(set) var totalCleared = 0
    private(set) var bestCombo = 0

    // UI/animation state
    private(set) var clearing: Set<Cell> = []
    private(set) var selection: Cell?
    private(set) var isResolving = false
    private(set) var comboBanner: ComboBanner?
    private(set) var outcome: GameOutcome?
    private(set) var hintMove: (Cell, Cell)?
    private(set) var didReshuffle = false

    var reduceMotion = false
    var hapticsEnabled = true

    struct ComboBanner: Identifiable {
        let id = UUID()
        let chain: Int
        let points: Int
        var text: String { chain >= 2 ? "Combo ×\(chain)!" : "+\(points)" }
    }

    enum GameOutcome: Equatable {
        case won(stars: Int)
        case lost
    }

    init(mode: GameMode, level: Level?, seed: UInt64, resume: SavedGame? = nil) {
        self.mode = mode
        self.level = level

        switch mode {
        case .level:
            self.rows = level?.rows ?? 7
            self.cols = level?.cols ?? 7
            self.moveLimit = level?.moves
            self.goal = level?.goal
        case .daily:
            self.rows = 8
            self.cols = 8
            self.moveLimit = 25
            self.goal = .score(target: 3000)
        case .zen:
            self.rows = 8
            self.cols = 8
            self.moveLimit = nil
            self.goal = nil
        }

        let engine = MatchEngine(colorCount: 6)

        if let resume,
           let savedBoard = Codec.decodeBoard(resume.boardData),
           savedBoard.rows == self.rows, savedBoard.cols == self.cols,
           let savedRNG = Codec.decodeRNG(resume.rngState) {
            self.board = savedBoard
            self.rng = savedRNG
            self.score = resume.score
            self.movesUsed = resume.movesUsed
        } else {
            var rng = SplitMix64(seed: seed)
            var b = engine.makeBoard(rows: self.rows, cols: self.cols, rng: &rng)
            if !engine.hasPossibleMove(b) {
                b = engine.reshuffle(b, rng: &rng)
            }
            self.board = b
            self.rng = rng
        }
    }

    var movesLeft: Int? {
        guard let moveLimit else { return nil }
        return max(0, moveLimit - movesUsed)
    }

    // MARK: - Goal progress

    /// 0...1 progress toward the goal (Zen has none).
    var goalProgress: Double {
        switch goal {
        case .none:
            return 0
        case .score(let target):
            guard target > 0 else { return 1 }
            return min(1, Double(score) / Double(target))
        case .clearColor(let color, let count):
            guard count > 0 else { return 1 }
            return min(1, Double(clearedByColor[color, default: 0]) / Double(count))
        }
    }

    var goalProgressText: String {
        switch goal {
        case .none: return ""
        case .score(let target): return "\(score) / \(target)"
        case .clearColor(let color, let count): return "\(clearedByColor[color, default: 0]) / \(count) \(color.name)"
        }
    }

    private var goalMet: Bool {
        switch goal {
        case .none: return false
        case .score(let target): return score >= target
        case .clearColor(let color, let count): return clearedByColor[color, default: 0] >= count
        }
    }

    // MARK: - Selection / swap input

    func tapGem(at cell: Cell) {
        guard !isResolving, outcome == nil, board.inBounds(cell) else { return }
        guard let current = selection else {
            selection = cell
            if hapticsEnabled { Haptics.tap() }
            return
        }
        if current == cell {
            selection = nil
            return
        }
        if board.areAdjacent(current, cell) {
            selection = nil
            attemptSwap(current, cell)
        } else {
            // Re-select the new gem instead.
            selection = cell
            if hapticsEnabled { Haptics.tap() }
        }
    }

    func dragSwap(from a: Cell, to b: Cell) {
        guard !isResolving, outcome == nil else { return }
        selection = nil
        guard board.areAdjacent(a, b) else { return }
        attemptSwap(a, b)
    }

    // MARK: - Core swap → resolve loop

    private func attemptSwap(_ a: Cell, _ b: Cell) {
        hintMove = nil
        var localRNG = rng
        let outcome = engine.resolveSwap(on: board, swap: a, b, rng: &localRNG)

        guard outcome.didMatch else {
            // No-op swap: brief "wobble" feedback by visually swapping then reverting.
            if hapticsEnabled { Haptics.warning() }
            showInvalidSwap(a, b)
            return
        }

        rng = localRNG
        movesUsed += 1
        isResolving = true

        // Animate the visual pre-swap, then play steps.
        var swapped = board
        swapped.swap(a, b)
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.16)) {
            board = swapped
        }

        Task { await playSteps(outcome) }
    }

    private func showInvalidSwap(_ a: Cell, _ b: Cell) {
        var swapped = board
        swapped.swap(a, b)
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.12)) {
            board = swapped
        }
        Task {
            try? await Task.sleep(nanoseconds: reduceMotion ? 1 : 160_000_000)
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.12)) {
                swapped.swap(a, b) // revert
                board = swapped
            }
        }
    }

    private func playSteps(_ result: SwapOutcome) async {
        let stepPause: UInt64 = reduceMotion ? 1 : 220_000_000
        let clearPause: UInt64 = reduceMotion ? 1 : 180_000_000

        for step in result.steps {
            switch step {
            case .clear(let cells, let points, let chain):
                score += points
                bestCombo = max(bestCombo, chain)
                withAnimation(reduceMotion ? nil : .easeOut(duration: 0.16)) {
                    clearing = cells
                }
                if chain >= 2 {
                    comboBanner = ComboBanner(chain: chain, points: points)
                }
                if hapticsEnabled {
                    if chain >= 2 { Haptics.cascade(intensity: CGFloat(min(chain, 5)) / 5.0) }
                    else { Haptics.match() }
                }
                try? await Task.sleep(nanoseconds: clearPause)

            case .spawnSpecial:
                // Visual handled when settle lands; tiny pause for readability.
                try? await Task.sleep(nanoseconds: reduceMotion ? 1 : 80_000_000)

            case .settle(let newBoard):
                withAnimation(reduceMotion ? nil : .spring(response: 0.32, dampingFraction: 0.72)) {
                    clearing = []
                    board = newBoard
                }
                try? await Task.sleep(nanoseconds: stepPause)
            }
        }

        // Merge tallies.
        for (color, n) in result.clearedByColor {
            clearedByColor[color, default: 0] += n
        }
        totalCleared += result.totalCleared

        clearing = []
        comboBanner = nil

        // Ensure the board always has a possible move (reshuffle if stuck).
        ensurePlayable()

        isResolving = false
        evaluateEndState()
    }

    private func ensurePlayable() {
        if !engine.hasPossibleMove(board) {
            var localRNG = rng
            let reshuffled = engine.reshuffle(board, rng: &localRNG)
            rng = localRNG
            didReshuffle = true
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.3)) {
                board = reshuffled
            }
            if hapticsEnabled { Haptics.tap() }
        }
    }

    func clearReshuffleFlag() { didReshuffle = false }

    // MARK: - Win / lose

    private func evaluateEndState() {
        guard mode != .zen else { return } // Zen never ends.
        if goalMet {
            let stars = level?.stars(forScore: score) ?? 3
            outcome = .won(stars: stars)
            if hapticsEnabled { Haptics.success() }
        } else if let left = movesLeft, left <= 0 {
            outcome = .lost
            if hapticsEnabled { Haptics.error() }
        }
    }

    // MARK: - Hint

    func requestHint() {
        guard !isResolving, outcome == nil else { return }
        hintMove = firstAvailableMove()
        if hapticsEnabled { Haptics.tap() }
    }

    private func firstAvailableMove() -> (Cell, Cell)? {
        for r in 0..<board.rows {
            for c in 0..<board.cols {
                let here = Cell(row: r, col: c)
                guard board.gem(at: here) != nil else { continue }
                for n in [Cell(row: r, col: c + 1), Cell(row: r + 1, col: c)] {
                    guard board.inBounds(n) else { continue }
                    var test = board
                    test.swap(here, n)
                    if engine.hasAnyMatch(test) { return (here, n) }
                }
            }
        }
        return nil
    }

    // MARK: - Persistence snapshot

    func snapshot() -> (board: Data, rng: Data, score: Int, moves: Int) {
        (Codec.encodeBoard(board), Codec.encodeRNG(rng), score, movesUsed)
    }
}

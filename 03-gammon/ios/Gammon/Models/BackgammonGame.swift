import Foundation
import Observation

// MARK: - Core Types

enum PieceColor: String, Equatable, Codable {
    case white, black
    var other: PieceColor { self == .white ? .black : .white }
    var displayName: String { self == .white ? "White" : "Black" }
}

struct BGPoint: Equatable {
    var count: Int
    var color: PieceColor?

    var isEmpty: Bool { count == 0 }
    var isBlot: Bool { count == 1 }

    mutating func add(color c: PieceColor) {
        color = c
        count += 1
    }

    mutating func remove() {
        count -= 1
        if count == 0 { color = nil }
    }
}

enum GameMode: Equatable {
    case vsAI(difficulty: Int)   // 1=easy 2=medium 3=hard
    case twoPlayer
}

enum BGPhase: Equatable {
    case rolling
    case moving
    case gameOver(PieceColor)
}

struct DiceState: Equatable {
    var die1: Int
    var die2: Int
    var movesLeft: [Int]

    init(d1: Int, d2: Int) {
        die1 = d1
        die2 = d2
        movesLeft = (d1 == d2) ? [d1, d1, d1, d1] : [d1, d2]
    }

    var isEmpty: Bool { movesLeft.isEmpty }
    var isDoubles: Bool { die1 == die2 }
}

// MARK: - Board Constants
// Points indexed 0–23.
// WHITE pieces move from index 23 → 0 (home board is indices 0–5).
// BLACK pieces move from index 0 → 23 (home board is indices 18–23).
// whiteBar / blackBar track pieces on bar.
// whiteOff / blackOff track borne-off pieces.

// MARK: - Game

@Observable
final class BackgammonGame {

    // Board state
    private(set) var points: [BGPoint] = Array(repeating: BGPoint(count: 0, color: nil), count: 24)
    private(set) var whiteBar: Int = 0
    private(set) var blackBar: Int = 0
    private(set) var whiteOff: Int = 0
    private(set) var blackOff: Int = 0

    // Turn state
    private(set) var currentPlayer: PieceColor = .white
    private(set) var phase: BGPhase = .rolling
    private(set) var dice: DiceState?

    // Selection state (for UI)
    private(set) var selectedFrom: Int? = nil       // point index, -1 = bar, nil = nothing
    private(set) var legalDests: [Int] = []         // point indices, -2 = bear off

    // Game metadata
    var mode: GameMode = .vsAI(difficulty: 2)
    private(set) var moveCount: Int = 0
    private(set) var gameStartDate: Date = .now

    // MARK: - Setup

    init(mode: GameMode = .vsAI(difficulty: 2)) {
        self.mode = mode
        setupBoard()
    }

    func newGame(mode: GameMode) {
        self.mode = mode
        setupBoard()
    }

    func setupBoard() {
        points = Array(repeating: BGPoint(count: 0, color: nil), count: 24)
        whiteBar = 0; blackBar = 0
        whiteOff = 0; blackOff = 0
        currentPlayer = .white
        phase = .rolling
        dice = nil
        selectedFrom = nil
        legalDests = []
        moveCount = 0
        gameStartDate = .now

        // Standard backgammon starting position
        // WHITE moves 23→0 (home = indices 0–5)
        points[23] = BGPoint(count: 2, color: .white)
        points[12] = BGPoint(count: 5, color: .white)
        points[7]  = BGPoint(count: 3, color: .white)
        points[5]  = BGPoint(count: 5, color: .white)

        // BLACK moves 0→23 (home = indices 18–23)
        points[0]  = BGPoint(count: 2, color: .black)
        points[11] = BGPoint(count: 5, color: .black)
        points[16] = BGPoint(count: 3, color: .black)
        points[18] = BGPoint(count: 5, color: .black)
    }

    // MARK: - Dice

    func rollDice() {
        guard case .rolling = phase else { return }
        let d1 = Int.random(in: 1...6)
        let d2 = Int.random(in: 1...6)
        let newDice = DiceState(d1: d1, d2: d2)
        dice = newDice
        let moves = generateAllLegalMoves(for: currentPlayer, diceState: newDice)
        if moves.isEmpty {
            // No legal moves, forfeit turn
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                self.endTurn()
            }
        } else {
            phase = .moving
        }
    }

    // MARK: - Legal Move Generation

    /// Returns all legal (from, to) pairs.
    /// from: 0–23 = board point index, -1 = bar
    /// to:   0–23 = board point index, -2 = bear off
    func generateAllLegalMoves(for player: PieceColor, diceState: DiceState) -> [(Int, Int)] {
        var result: [(Int, Int)] = []
        let uniqueDice = Array(Set(diceState.movesLeft))
        let barCount = player == .white ? whiteBar : blackBar

        if barCount > 0 {
            // Must enter from bar first
            for die in uniqueDice {
                if let dest = barEntryDest(for: player, die: die), canLand(at: dest, for: player) {
                    result.append((-1, dest))
                }
            }
        } else {
            let canBO = canBearOff(player: player)
            for i in 0..<24 where points[i].color == player && points[i].count > 0 {
                for die in uniqueDice {
                    let dest = player == .white ? i - die : i + die
                    if dest >= 0 && dest < 24 {
                        if canLand(at: dest, for: player) {
                            result.append((i, dest))
                        }
                    } else if canBO {
                        // Potential bear-off
                        if player == .white && dest < 0 {
                            if exactBearOff(from: i, die: die, player: player) {
                                result.append((i, -2))
                            }
                        } else if player == .black && dest >= 24 {
                            if exactBearOff(from: i, die: die, player: player) {
                                result.append((i, -2))
                            }
                        }
                    }
                }
            }
        }

        // Deduplicate
        var seen = Set<String>()
        return result.filter { move in
            let key = "\(move.0):\(move.1)"
            return seen.insert(key).inserted
        }
    }

    private func barEntryDest(for player: PieceColor, die: Int) -> Int? {
        // WHITE enters opponent's home board (indices 18–23), die maps to index 24-die
        // BLACK enters opponent's home board (indices 0–5), die maps to index die-1
        if player == .white {
            let dest = 24 - die  // die=1→23, die=6→18
            return (dest >= 18 && dest <= 23) ? dest : nil
        } else {
            let dest = die - 1   // die=1→0, die=6→5
            return (dest >= 0 && dest <= 5) ? dest : nil
        }
    }

    private func canLand(at index: Int, for player: PieceColor) -> Bool {
        guard index >= 0 && index < 24 else { return false }
        let p = points[index]
        return p.color == nil || p.color == player || p.isBlot
    }

    func canBearOff(player: PieceColor) -> Bool {
        if player == .white {
            // All pieces must be in home board (indices 0–5) or already borne off
            let barAndOutside = whiteBar + (6..<24).reduce(0) { acc, i in
                points[i].color == .white ? acc + points[i].count : acc
            }
            return barAndOutside == 0
        } else {
            // Black home = indices 18–23
            let barAndOutside = blackBar + (0..<18).reduce(0) { acc, i in
                points[i].color == .black ? acc + points[i].count : acc
            }
            return barAndOutside == 0
        }
    }

    /// Can we bear off from point `i` using `die`?
    private func exactBearOff(from i: Int, die: Int, player: PieceColor) -> Bool {
        if player == .white {
            // Home indices 0–5. Bearing off means moving to index < 0.
            let dest = i - die
            if dest == -1 { return true }  // exact
            if dest < -1 {
                // Overshoot: only if no pieces on higher points
                return !hasHigherPoint(than: i, for: player)
            }
            return false
        } else {
            // Black home indices 18–23. Bearing off means moving to index >= 24.
            let dest = i + die
            if dest == 24 { return true }  // exact
            if dest > 24 {
                return !hasHigherPoint(than: i, for: player)
            }
            return false
        }
    }

    /// "Higher" means further from bearing off (further from home edge)
    private func hasHigherPoint(than point: Int, for player: PieceColor) -> Bool {
        if player == .white {
            // Higher = larger index (further from 0)
            return (point + 1..<6).contains { i in points[i].color == .white && points[i].count > 0 }
        } else {
            // Higher = smaller index (further from 23)
            return (18..<point).contains { i in points[i].color == .black && points[i].count > 0 }
        }
    }

    // MARK: - Selection / Tap Handling

    func tapPoint(_ idx: Int) {
        guard case .moving = phase, var currentDice = dice else { return }
        let player = currentPlayer

        if let from = selectedFrom {
            // Attempt move
            if legalDests.contains(idx) {
                applyMove(from: from, to: idx, player: player)
                clearSelection()
                afterMove()
                return
            }
            // Re-select own piece
            if points[safe: idx]?.color == player {
                selectedFrom = idx
                legalDests = destsFrom(idx, player: player, diceState: dice ?? currentDice)
                return
            }
            // Deselect
            clearSelection()
        } else {
            // Check bar first
            let barCount = player == .white ? whiteBar : blackBar
            if barCount > 0 { return }  // Must tap bar

            if points[safe: idx]?.color == player {
                selectedFrom = idx
                legalDests = destsFrom(idx, player: player, diceState: dice ?? currentDice)
            }
        }
    }

    func tapBar() {
        guard case .moving = phase, let currentDice = dice else { return }
        let player = currentPlayer
        let barCount = player == .white ? whiteBar : blackBar
        guard barCount > 0 else { return }

        if selectedFrom == -1 {
            clearSelection()
        } else {
            selectedFrom = -1
            legalDests = destsFrom(-1, player: player, diceState: currentDice)
        }
    }

    func tapBearOff() {
        guard case .moving = phase, let _ = dice else { return }
        guard let from = selectedFrom, legalDests.contains(-2) else { return }
        applyMove(from: from, to: -2, player: currentPlayer)
        clearSelection()
        afterMove()
    }

    func clearSelection() {
        selectedFrom = nil
        legalDests = []
    }

    private func destsFrom(_ from: Int, player: PieceColor, diceState: DiceState) -> [Int] {
        let all = generateAllLegalMoves(for: player, diceState: diceState)
        return Array(Set(all.filter { $0.0 == from }.map { $0.1 }))
    }

    // MARK: - Move Application

    func applyMove(from: Int, to: Int, player: PieceColor) {
        guard var currentDice = dice else { return }

        let die: Int
        if from == -1 {
            // From bar
            die = player == .white ? (24 - to) : (to + 1)
            if player == .white { whiteBar -= 1 } else { blackBar -= 1 }
        } else {
            die = player == .white ? (from - to) : (to - from)
            points[from].remove()
        }

        if to == -2 {
            // Bear off
            if player == .white { whiteOff += 1 } else { blackOff += 1 }
        } else {
            // Hit blot?
            if points[to].isBlot && points[to].color == player.other {
                if player.other == .white { whiteBar += 1 } else { blackBar += 1 }
                points[to] = BGPoint(count: 0, color: nil)
            }
            points[to].add(color: player)
        }

        // Consume die
        if let idx = currentDice.movesLeft.firstIndex(of: die) {
            currentDice.movesLeft.remove(at: idx)
        } else {
            // Try higher die for overshoot bear-off
            if let idx = currentDice.movesLeft.indices.first(where: { currentDice.movesLeft[$0] > die }) {
                currentDice.movesLeft.remove(at: idx)
            }
        }
        dice = currentDice
        moveCount += 1
    }

    private func afterMove() {
        checkGameOver()
        guard !isGameOver() else { return }

        let remaining = dice.map { generateAllLegalMoves(for: currentPlayer, diceState: $0) } ?? []
        if dice?.isEmpty == true || remaining.isEmpty {
            endTurn()
        }
    }

    // MARK: - AI

    func makeAITurn() {
        guard case .vsAI(let diff) = mode else { return }
        guard case .moving = phase, let currentDice = dice else { return }

        var remainingDice = currentDice
        var continueMoving = true

        while continueMoving {
            let moves = generateAllLegalMoves(for: currentPlayer, diceState: remainingDice)
            guard !moves.isEmpty, !remainingDice.isEmpty else {
                continueMoving = false
                break
            }

            let move = BackgammonAI.pickMove(moves: moves, game: self, difficulty: diff)
            applyMove(from: move.0, to: move.1, player: currentPlayer)
            checkGameOver()
            if isGameOver() { return }
            remainingDice = dice ?? remainingDice
            continueMoving = !remainingDice.isEmpty
        }

        endTurn()
    }

    // MARK: - Turn Management

    func endTurn() {
        dice = nil
        selectedFrom = nil
        legalDests = []
        currentPlayer = currentPlayer.other
        phase = .rolling
    }

    func forfeitTurn() {
        guard case .moving = phase else { return }
        endTurn()
    }

    // MARK: - Game Over

    private func checkGameOver() {
        if whiteOff == 15 { phase = .gameOver(.white) }
        else if blackOff == 15 { phase = .gameOver(.black) }
    }

    func isGameOver() -> Bool {
        if case .gameOver = phase { return true }
        return false
    }

    var winner: PieceColor? {
        if case .gameOver(let w) = phase { return w }
        return nil
    }

    // MARK: - Gammon / Backgammon Detection

    var isGammon: Bool {
        if let w = winner {
            return w == .white ? blackOff == 0 : whiteOff == 0
        }
        return false
    }

    var isBackgammon: Bool {
        guard isGammon else { return false }
        if let w = winner {
            if w == .white {
                return blackBar > 0 || (18..<24).contains { i in points[i].color == .black && points[i].count > 0 }
            } else {
                return whiteBar > 0 || (0..<6).contains { i in points[i].color == .white && points[i].count > 0 }
            }
        }
        return false
    }

    // MARK: - Pip Count

    func pipCount(for player: PieceColor) -> Int {
        var total = 0
        if player == .white {
            for i in 0..<24 where points[i].color == .white {
                total += points[i].count * (i + 1)  // pip distance
            }
            total += whiteBar * 25
        } else {
            for i in 0..<24 where points[i].color == .black {
                total += points[i].count * (24 - i)
            }
            total += blackBar * 25
        }
        return total
    }
}

// MARK: - Array Extension

extension Array {
    subscript(safe index: Int) -> Element? {
        guard index >= 0 && index < count else { return nil }
        return self[index]
    }
}

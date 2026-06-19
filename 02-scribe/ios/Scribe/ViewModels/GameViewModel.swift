import Foundation
import SwiftUI

@Observable
final class GameViewModel {
    var board: [[BoardSquare]] = BoardLayout.makeBoard()
    var playerRack: [Tile] = []
    var bag: [Tile] = []
    var score: Int = 0
    var turn: Int = 1
    var placedThisTurn: [(row: Int, col: Int)] = []
    var selectedTileIndex: Int? = nil
    var message: String = ""
    var showMessage: Bool = false
    var isGameOver: Bool = false
    var passCount: Int = 0
    var playedWords: [(word: String, score: Int)] = []
    var consecutivePasses = 0

    var hapticsEnabled = true

    init() {
        startNewGame()
    }

    func startNewGame() {
        board = BoardLayout.makeBoard()
        bag = LetterValues.makeBag()
        playerRack = []
        drawTiles(count: 7)
        score = 0
        turn = 1
        placedThisTurn = []
        selectedTileIndex = nil
        isGameOver = false
        playedWords = []
        consecutivePasses = 0
        message = ""
        showMessage = false
    }

    private func drawTiles(count: Int) {
        let draw = min(count, bag.count)
        for _ in 0..<draw {
            playerRack.append(bag.removeLast())
        }
    }

    func selectRackTile(at index: Int) {
        if selectedTileIndex == index {
            selectedTileIndex = nil
        } else {
            selectedTileIndex = index
        }
        if hapticsEnabled { UISelectionFeedbackGenerator().selectionChanged() }
    }

    func placeTile(row: Int, col: Int) {
        guard let tileIdx = selectedTileIndex else { return }
        guard board[row][col].tile == nil else { return }
        guard tileIdx < playerRack.count else { return }
        board[row][col].tile = playerRack[tileIdx]
        playerRack.remove(at: tileIdx)
        placedThisTurn.append((row, col))
        selectedTileIndex = nil
        if hapticsEnabled { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    }

    func recallTiles() {
        for pos in placedThisTurn.reversed() {
            if let tile = board[pos.row][pos.col].tile {
                playerRack.append(tile)
                board[pos.row][pos.col].tile = nil
            }
        }
        placedThisTurn = []
        if hapticsEnabled { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
    }

    func playWord() -> Bool {
        guard !placedThisTurn.isEmpty else {
            flash("Place tiles first")
            return false
        }
        let placements = placedThisTurn.sorted { $0.row == $1.row ? $0.col < $1.col : $0.row < $1.row }
        guard isValidPlacement(placements) else {
            flash("Tiles must be in one row or column")
            recallTiles()
            return false
        }
        let words = extractWords(placements: placements)
        for word in words {
            guard WordValidator.isValid(word.word) else {
                flash("\(word.word) is not valid")
                recallTiles()
                return false
            }
        }
        let turnScore = words.reduce(0) { $0 + $1.score }
        let bonus = playerRack.isEmpty ? 50 : 0
        score += turnScore + bonus
        for w in words {
            playedWords.append(w)
        }
        consecutivePasses = 0
        turn += 1
        drawTiles(count: placedThisTurn.count)
        placedThisTurn = []
        if hapticsEnabled { UINotificationFeedbackGenerator().notificationOccurred(.success) }
        if playerRack.isEmpty && bag.isEmpty {
            isGameOver = true
        }
        return true
    }

    func passTurn() {
        recallTiles()
        consecutivePasses += 1
        turn += 1
        if consecutivePasses >= 6 { isGameOver = true }
        if hapticsEnabled { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
    }

    func exchangeTiles(_ indices: IndexSet) {
        guard bag.count >= indices.count else {
            flash("Not enough tiles in bag")
            return
        }
        var toExchange: [Tile] = []
        for idx in indices.sorted().reversed() {
            toExchange.append(playerRack.remove(at: idx))
        }
        drawTiles(count: toExchange.count)
        bag.insert(contentsOf: toExchange, at: 0)
        bag.shuffle()
        placedThisTurn = []
        turn += 1
        consecutivePasses += 1
        if consecutivePasses >= 6 { isGameOver = true }
    }

    private func flash(_ msg: String) {
        message = msg
        showMessage = true
    }

    private func isValidPlacement(_ placements: [(row: Int, col: Int)]) -> Bool {
        if placements.isEmpty { return false }
        if placements.count == 1 { return true }
        let allRow = placements.allSatisfy { $0.row == placements[0].row }
        let allCol = placements.allSatisfy { $0.col == placements[0].col }
        return allRow || allCol
    }

    private func extractWords(placements: [(row: Int, col: Int)]) -> [(word: String, score: Int)] {
        var words: [(word: String, score: Int)] = []
        let allRow = placements.count == 1 || placements.allSatisfy { $0.row == placements[0].row }
        let allCol = placements.count == 1 || placements.allSatisfy { $0.col == placements[0].col }

        if allRow && placements.count > 1 || (placements.count == 1) {
            let row = placements[0].row
            let minCol = min(placements.map { $0.col }.min()!, 0)
            var c = 0
            while c < BoardLayout.size && board[row][c].tile == nil { c += 1 }
            let startCol = c
            var word = ""
            var wordScore = 0
            var wordMult = 1
            c = startCol
            while c < BoardLayout.size, let tile = board[row][c].tile {
                let sq = board[row][c]
                let placed = placements.contains { $0.row == row && $0.col == c }
                var pts = tile.points
                if placed {
                    switch sq.type {
                    case .doubleLetter: pts *= 2
                    case .tripleLetter: pts *= 3
                    case .doubleWord, .center: wordMult *= 2
                    case .tripleWord: wordMult *= 3
                    default: break
                    }
                }
                wordScore += pts
                word.append(tile.letter)
                c += 1
            }
            if word.count >= 2 { words.append((word: word, score: wordScore * wordMult)) }
            _ = minCol
        }

        if allCol && placements.count > 1 || (placements.count == 1 && allCol) {
            let col = placements[0].col
            var r = 0
            while r < BoardLayout.size && board[r][col].tile == nil { r += 1 }
            let startRow = r
            var word = ""
            var wordScore = 0
            var wordMult = 1
            r = startRow
            while r < BoardLayout.size, let tile = board[r][col].tile {
                let sq = board[r][col]
                let placed = placements.contains { $0.row == r && $0.col == col }
                var pts = tile.points
                if placed {
                    switch sq.type {
                    case .doubleLetter: pts *= 2
                    case .tripleLetter: pts *= 3
                    case .doubleWord, .center: wordMult *= 2
                    case .tripleWord: wordMult *= 3
                    default: break
                    }
                }
                wordScore += pts
                word.append(tile.letter)
                r += 1
            }
            if word.count >= 2 { words.append((word: word, score: wordScore * wordMult)) }
        }
        return words
    }
}

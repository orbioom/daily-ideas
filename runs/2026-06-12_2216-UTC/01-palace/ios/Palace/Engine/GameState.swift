import Foundation

/// A complete, Codable snapshot of a Klondike position.
/// Used for undo history and for saving the in-progress game to disk.
struct GameState: Codable, Equatable {
    var stock: [Card]
    var waste: [Card]
    var foundations: [[Card]]   // 4 piles, ace → king, one suit each once started
    var tableau: [[Card]]       // 7 columns
    var score: Int
    var moves: Int
    var accumulatedSeconds: Double
    var drawThree: Bool
    var recycles: Int

    static func newDeal(drawThree: Bool) -> GameState {
        var deck = Card.fullDeck().shuffled()
        var tableau: [[Card]] = Array(repeating: [], count: 7)
        for column in 0..<7 {
            for row in 0...column {
                guard var card = deck.popLast() else { continue }
                card.faceUp = (row == column)
                tableau[column].append(card)
            }
        }
        // Remaining cards form the stock, face down.
        let stock = deck.map { card -> Card in
            var c = card
            c.faceUp = false
            return c
        }
        return GameState(
            stock: stock,
            waste: [],
            foundations: Array(repeating: [], count: 4),
            tableau: tableau,
            score: 0,
            moves: 0,
            accumulatedSeconds: 0,
            drawThree: drawThree,
            recycles: 0
        )
    }

    var foundationCount: Int { foundations.reduce(0) { $0 + $1.count } }
    var isWon: Bool { foundationCount == 52 }
}

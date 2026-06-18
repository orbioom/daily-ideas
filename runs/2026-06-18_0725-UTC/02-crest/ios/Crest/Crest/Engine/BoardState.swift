import Foundation

/// A fully Codable snapshot of an in-progress game. Used both for undo snapshots
/// and for SwiftData JSON persistence (resume-on-relaunch).
struct BoardState: Codable, Equatable {
    var layout: BoardLayout
    var dealNumber: Int
    var isDaily: Bool

    /// tableau[i] is the card at position i, or nil if it has been cleared.
    var tableau: [Card?]
    /// Stock pile (top of stock is the LAST element).
    var stock: [Card]
    /// Waste pile (current playable card is the LAST element).
    var waste: [Card]

    var score: Int
    var combo: Int          // current consecutive-clears streak
    var longestCombo: Int
    var cardsCleared: Int

    /// Accumulated elapsed seconds from previous foreground sessions.
    var elapsedAccum: Double

    var topWaste: Card? { waste.last }
}

/// Outcome state of the game, derived from a BoardState.
enum GameOutcome: Equatable {
    case playing
    case won
    case lost
}

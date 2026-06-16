import Foundation

/// A location on the board that can be the source or destination of a move.
enum Location: Equatable, Hashable {
    case cascade(Int)   // column index 0...7
    case freeCell(Int)  // cell index 0...3
    case foundation(Suit)
}

/// A requested move. `count` is how many cards form the moved run (only meaningful
/// for cascade-to-cascade supermoves; otherwise 1).
struct Move: Equatable {
    let from: Location
    let to: Location
    let count: Int

    init(from: Location, to: Location, count: Int = 1) {
        self.from = from
        self.to = to
        self.count = count
    }
}

/// Calm, typed errors. Never thrown to the user as a crash — always caught and
/// surfaced as a gentle message or simply ignored (invalid move = no-op).
enum FreeCellError: Error, Equatable {
    case invalidSource
    case invalidDestination
    case illegalMove
    case notEnoughSpaceForSupermove
    case emptySource

    var message: String {
        switch self {
        case .invalidSource: return "That card can't be picked up."
        case .invalidDestination: return "That move isn't allowed there."
        case .illegalMove: return "That move isn't allowed."
        case .notEnoughSpaceForSupermove: return "Not enough free cells or empty columns to move that many cards."
        case .emptySource: return "There's no card to move there."
        }
    }
}

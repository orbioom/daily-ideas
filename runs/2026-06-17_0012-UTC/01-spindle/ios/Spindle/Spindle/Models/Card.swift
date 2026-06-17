import SwiftUI

/// The four suits. `Codable` so the full board can be JSON-encoded for SavedGame.
enum Suit: String, Codable, CaseIterable, Identifiable {
    case spades, hearts, diamonds, clubs
    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .spades: return "♠"
        case .hearts: return "♥"
        case .diamonds: return "♦"
        case .clubs: return "♣"
        }
    }

    /// Red suits render in red ink; black suits in near-black.
    var isRed: Bool { self == .hearts || self == .diamonds }

    /// Spoken name for VoiceOver.
    var spokenName: String { rawValue }
}

/// A playing card. Rank is 1 (Ace) … 13 (King).
/// `Identifiable` with a stable UUID so SwiftUI can diff cards across moves.
struct Card: Identifiable, Codable, Equatable {
    let id: UUID
    let suit: Suit
    /// 1 = Ace … 11 = Jack, 12 = Queen, 13 = King.
    let rank: Int
    var faceUp: Bool

    init(id: UUID = UUID(), suit: Suit, rank: Int, faceUp: Bool = false) {
        self.id = id
        self.suit = suit
        self.rank = min(13, max(1, rank))
        self.faceUp = faceUp
    }

    /// Short rank label: A, 2…10, J, Q, K.
    var rankLabel: String {
        switch rank {
        case 1: return "A"
        case 11: return "J"
        case 12: return "Q"
        case 13: return "K"
        default: return "\(rank)"
        }
    }

    /// Full rank name spoken by VoiceOver.
    var rankName: String {
        switch rank {
        case 1: return "Ace"
        case 11: return "Jack"
        case 12: return "Queen"
        case 13: return "King"
        default: return "\(rank)"
        }
    }

    /// "Ace of spades" — used for VoiceOver labels.
    var spokenName: String { "\(rankName) of \(suit.spokenName)" }

    static func == (lhs: Card, rhs: Card) -> Bool { lhs.id == rhs.id }
}

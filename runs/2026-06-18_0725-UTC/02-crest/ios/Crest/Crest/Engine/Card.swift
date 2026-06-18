import SwiftUI

enum Suit: Int, Codable, CaseIterable, Identifiable {
    case spades, hearts, diamonds, clubs
    var id: Int { rawValue }

    var symbol: String {
        switch self {
        case .spades: return "♠"
        case .hearts: return "♥"
        case .diamonds: return "♦"
        case .clubs: return "♣"
        }
    }

    var isRed: Bool { self == .hearts || self == .diamonds }

    var color: Color { isRed ? Theme.suitRed : Theme.suitBlack }

    var accessibilityName: String {
        switch self {
        case .spades: return "spades"
        case .hearts: return "hearts"
        case .diamonds: return "diamonds"
        case .clubs: return "clubs"
        }
    }
}

/// A playing card. Rank is 1...13 (Ace ... King).
struct Card: Codable, Equatable, Identifiable, Hashable {
    let rank: Int   // 1 = Ace, 11 = Jack, 12 = Queen, 13 = King
    let suit: Suit

    var id: Int { (suit.rawValue * 13) + rank } // unique within a 52-card deck

    var rankLabel: String {
        switch rank {
        case 1: return "A"
        case 11: return "J"
        case 12: return "Q"
        case 13: return "K"
        default: return String(rank)
        }
    }

    var rankName: String {
        switch rank {
        case 1: return "Ace"
        case 11: return "Jack"
        case 12: return "Queen"
        case 13: return "King"
        default: return String(rank)
        }
    }

    var accessibilityName: String { "\(rankName) of \(suit.accessibilityName)" }

    /// A full ordered 52-card deck.
    static var fullDeck: [Card] {
        var cards: [Card] = []
        cards.reserveCapacity(52)
        for suit in Suit.allCases {
            for rank in 1...13 {
                cards.append(Card(rank: rank, suit: suit))
            }
        }
        return cards
    }

    /// True when `self` may be placed on `other` given wrap-around rules.
    /// Ranks are adjacent if they differ by 1; with wrap, King (13) and Ace (1) are also adjacent.
    func isAdjacent(to other: Card, wrap: Bool) -> Bool {
        let diff = abs(rank - other.rank)
        if diff == 1 { return true }
        if wrap && diff == 12 { return true } // 13 vs 1
        return false
    }
}

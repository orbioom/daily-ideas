import Foundation

enum Suit: String, CaseIterable, Codable {
    case hearts = "♥", diamonds = "♦", spades = "♠", clubs = "♣"

    var isRed: Bool { self == .hearts || self == .diamonds }
}

struct PlayingCard: Identifiable, Equatable, Codable {
    let id: UUID
    let rank: Int  // 1=A, 11=J, 12=Q, 13=K
    let suit: Suit

    init(rank: Int, suit: Suit) {
        self.id = UUID()
        self.rank = rank
        self.suit = suit
    }

    var rankLabel: String {
        switch rank {
        case 1: return "A"
        case 11: return "J"
        case 12: return "Q"
        case 13: return "K"
        default: return "\(rank)"
        }
    }

    var displayName: String { "\(rankLabel)\(suit.rawValue)" }

    // King can be removed alone; others need a partner summing to 13
    var canRemoveAlone: Bool { rank == 13 }

    static func pairSumsTo13(_ a: PlayingCard, _ b: PlayingCard) -> Bool {
        a.rank + b.rank == 13
    }

    static func fullDeck() -> [PlayingCard] {
        var deck: [PlayingCard] = []
        for suit in Suit.allCases {
            for rank in 1...13 {
                deck.append(PlayingCard(rank: rank, suit: suit))
            }
        }
        return deck
    }
}

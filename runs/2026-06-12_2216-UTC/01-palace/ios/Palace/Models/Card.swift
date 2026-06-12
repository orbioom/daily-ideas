import Foundation

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

    var isRed: Bool { self == .hearts || self == .diamonds }

    var displayName: String { rawValue.capitalized }
}

enum Rank: Int, Codable, CaseIterable, Comparable {
    case ace = 1, two, three, four, five, six, seven, eight, nine, ten, jack, queen, king

    static func < (lhs: Rank, rhs: Rank) -> Bool { lhs.rawValue < rhs.rawValue }

    var label: String {
        switch self {
        case .ace: return "A"
        case .jack: return "J"
        case .queen: return "Q"
        case .king: return "K"
        default: return String(rawValue)
        }
    }

    var spokenName: String {
        switch self {
        case .ace: return "ace"
        case .jack: return "jack"
        case .queen: return "queen"
        case .king: return "king"
        default: return String(rawValue)
        }
    }
}

struct Card: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let suit: Suit
    let rank: Rank
    var faceUp: Bool

    init(suit: Suit, rank: Rank, faceUp: Bool = false) {
        self.id = UUID()
        self.suit = suit
        self.rank = rank
        self.faceUp = faceUp
    }

    var isRed: Bool { suit.isRed }

    var accessibilityName: String { "\(rank.spokenName) of \(suit.rawValue)" }

    static func fullDeck() -> [Card] {
        var deck: [Card] = []
        for suit in Suit.allCases {
            for rank in Rank.allCases {
                deck.append(Card(suit: suit, rank: rank))
            }
        }
        return deck
    }
}

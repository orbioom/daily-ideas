import Foundation

enum Suit: String, CaseIterable, Codable {
    case spades = "♠"
    case hearts = "♥"
    case diamonds = "♦"
    case clubs = "♣"

    var color: String { (self == .hearts || self == .diamonds) ? "red" : "black" }

    /// The suit whose Jack becomes the left bower when this suit is trump.
    /// Spades/Clubs are same color, Hearts/Diamonds are same color.
    var sameSuit: Suit {
        switch self {
        case .spades: return .clubs
        case .clubs: return .spades
        case .hearts: return .diamonds
        case .diamonds: return .hearts
        }
    }
}

enum Rank: Int, CaseIterable, Codable, Comparable {
    case nine = 9, ten = 10, jack = 11, queen = 12, king = 13, ace = 14
    static func < (lhs: Rank, rhs: Rank) -> Bool { lhs.rawValue < rhs.rawValue }
    var display: String {
        switch self {
        case .nine: return "9"
        case .ten: return "10"
        case .jack: return "J"
        case .queen: return "Q"
        case .king: return "K"
        case .ace: return "A"
        }
    }
}

struct Card: Equatable, Codable, Identifiable {
    let suit: Suit
    let rank: Rank
    var id: String { "\(rank.rawValue)\(suit.rawValue)" }

    var display: String { "\(rank.display)\(suit.rawValue)" }

    /// Returns true if this card is the left bower (J of same-color suit as trump).
    func isLeftBower(trump: Suit) -> Bool {
        rank == .jack && suit == trump.sameSuit
    }

    /// Returns true if this card is the right bower (J of trump suit).
    func isRightBower(trump: Suit) -> Bool {
        rank == .jack && suit == trump
    }

    /// The effective suit for following-suit purposes.
    /// The left bower counts as trump suit even though its printed suit differs.
    func effectiveSuit(trump: Suit) -> Suit {
        if isLeftBower(trump: trump) { return trump }
        return suit
    }

    /// Power ranking within trump: right bower (15) > left bower (14) > A-K-Q-10-9.
    func trumpPower(trump: Suit) -> Int {
        if isRightBower(trump: trump) { return 15 }
        if isLeftBower(trump: trump) { return 14 }
        return rank.rawValue
    }

    /// Build and shuffle a standard 24-card Euchre deck (9 through Ace, all four suits).
    static func euchreDecks() -> [Card] {
        var deck: [Card] = []
        for suit in Suit.allCases {
            for rank in Rank.allCases {
                deck.append(Card(suit: suit, rank: rank))
            }
        }
        return deck.shuffled()
    }
}

import Foundation

enum Suit: Int, CaseIterable, Comparable, Hashable {
    case clubs = 0, diamonds, spades, hearts

    var symbol: String {
        switch self { case .clubs: return "♣"; case .diamonds: return "♦"; case .spades: return "♠"; case .hearts: return "♥" }
    }
    var name: String {
        switch self { case .clubs: return "Clubs"; case .diamonds: return "Diamonds"; case .spades: return "Spades"; case .hearts: return "Hearts" }
    }
    var isRed: Bool { self == .hearts || self == .diamonds }

    static func < (lhs: Suit, rhs: Suit) -> Bool { lhs.rawValue < rhs.rawValue }
}

enum Rank: Int, CaseIterable, Comparable, Hashable {
    case two = 2, three, four, five, six, seven, eight, nine, ten
    case jack = 11, queen, king, ace

    var display: String {
        switch self {
        case .jack:  return "J"
        case .queen: return "Q"
        case .king:  return "K"
        case .ace:   return "A"
        default:     return "\(rawValue)"
        }
    }

    static func < (lhs: Rank, rhs: Rank) -> Bool { lhs.rawValue < rhs.rawValue }
}

struct Card: Hashable, Identifiable {
    let suit: Suit
    let rank: Rank

    var id: Int { suit.rawValue * 13 + rank.rawValue }
    var displayName: String { "\(rank.display)\(suit.symbol)" }
    var isHeart: Bool { suit == .hearts }
    var isQueenOfSpades: Bool { suit == .spades && rank == .queen }
    var pointValue: Int {
        if isHeart { return 1 }
        if isQueenOfSpades { return 13 }
        return 0
    }

    static let queenOfSpades = Card(suit: .spades, rank: .queen)
    static let twoOfClubs = Card(suit: .clubs, rank: .two)

    static var fullDeck: [Card] {
        Suit.allCases.flatMap { suit in Rank.allCases.map { Card(suit: suit, rank: $0) } }
    }
}

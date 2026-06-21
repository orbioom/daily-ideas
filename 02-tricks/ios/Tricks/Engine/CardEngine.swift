import Foundation

enum Suit: Int, CaseIterable, Comparable, Codable {
    case clubs = 0, diamonds = 1, hearts = 2, spades = 3
    static func < (lhs: Suit, rhs: Suit) -> Bool { lhs.rawValue < rhs.rawValue }
    var symbol: String { ["♣","♦","♥","♠"][rawValue] }
    var name: String { ["Clubs","Diamonds","Hearts","Spades"][rawValue] }
    var isRed: Bool { self == .diamonds || self == .hearts }
}

enum Rank: Int, CaseIterable, Comparable, Codable {
    case two=2, three=3, four=4, five=5, six=6, seven=7, eight=8, nine=9, ten=10, jack=11, queen=12, king=13, ace=14
    static func < (lhs: Rank, rhs: Rank) -> Bool { lhs.rawValue < rhs.rawValue }
    var symbol: String {
        switch self {
        case .jack: return "J"; case .queen: return "Q"; case .king: return "K"; case .ace: return "A"
        default: return "\(rawValue)"
        }
    }
}

struct Card: Identifiable, Equatable, Codable {
    let suit: Suit
    let rank: Rank
    var id: String { "\(rank.rawValue)-\(suit.rawValue)" }

    static func deck() -> [Card] {
        var cards: [Card] = []
        for suit in Suit.allCases { for rank in Rank.allCases { cards.append(Card(suit: suit, rank: rank)) } }
        return cards
    }

    static func shuffledDeck() -> [Card] {
        var d = deck(); d.shuffle(); return d
    }

    func beats(_ other: Card, led: Suit) -> Bool {
        if suit == .spades && other.suit != .spades { return true }
        if other.suit == .spades && suit != .spades { return false }
        if suit == other.suit { return rank > other.rank }
        if suit == led { return true }
        return false
    }
}

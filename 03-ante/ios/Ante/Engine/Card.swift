import Foundation

enum Suit: String, CaseIterable, Codable {
    case spades = "♠"
    case hearts = "♥"
    case diamonds = "♦"
    case clubs = "♣"

    var isRed: Bool { self == .hearts || self == .diamonds }

    var sortOrder: Int {
        switch self {
        case .spades: return 0
        case .hearts: return 1
        case .diamonds: return 2
        case .clubs: return 3
        }
    }
}

enum Rank: Int, CaseIterable, Codable {
    case ace = 1, two, three, four, five, six, seven, eight, nine, ten, jack, queen, king

    var displayName: String {
        switch self {
        case .ace: return "A"
        case .jack: return "J"
        case .queen: return "Q"
        case .king: return "K"
        default: return "\(rawValue)"
        }
    }

    var ginValue: Int { min(rawValue, 10) }
}

struct PlayingCard: Identifiable, Equatable, Hashable {
    let id: UUID
    let rank: Rank
    let suit: Suit

    init(rank: Rank, suit: Suit) {
        self.id = UUID()
        self.rank = rank
        self.suit = suit
    }

    var displayName: String { "\(rank.displayName)\(suit.rawValue)" }
    var value: Int { rank.ginValue }
    var sortKey: Int { rank.rawValue * 4 + suit.sortOrder }
}

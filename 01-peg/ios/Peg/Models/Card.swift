import Foundation

struct Card: Identifiable, Equatable, Hashable {
    let id: UUID
    let suit: Suit
    let rank: Rank

    init(suit: Suit, rank: Rank) {
        self.id = UUID()
        self.suit = suit
        self.rank = rank
    }

    enum Suit: String, CaseIterable {
        case clubs = "♣", diamonds = "♦", hearts = "♥", spades = "♠"
        var isRed: Bool { self == .hearts || self == .diamonds }
    }

    enum Rank: Int, CaseIterable, Comparable {
        case ace = 1, two, three, four, five, six, seven, eight, nine, ten, jack, queen, king

        static func < (lhs: Rank, rhs: Rank) -> Bool { lhs.rawValue < rhs.rawValue }

        var display: String {
            switch self {
            case .ace: return "A"
            case .jack: return "J"
            case .queen: return "Q"
            case .king: return "K"
            default: return "\(rawValue)"
            }
        }

        var value: Int { min(rawValue, 10) }
    }
}

extension Card {
    var display: String { "\(rank.display)\(suit.rawValue)" }
}

func makeDeck() -> [Card] {
    var deck: [Card] = []
    for suit in Card.Suit.allCases {
        for rank in Card.Rank.allCases {
            deck.append(Card(suit: suit, rank: rank))
        }
    }
    return deck
}

func shuffledDeck() -> [Card] {
    var deck = makeDeck()
    deck.shuffle()
    return deck
}

func combinations<T>(_ array: [T], _ k: Int) -> [[T]] {
    guard k > 0 && k <= array.count else { return k == 0 ? [[]] : [] }
    if k == 1 { return array.map { [$0] } }
    var result: [[T]] = []
    for i in 0...(array.count - k) {
        let rest = combinations(Array(array[(i+1)...]), k - 1)
        result += rest.map { [array[i]] + $0 }
    }
    return result
}

import Foundation

struct Deck {
    private(set) var cards: [PlayingCard]

    init() {
        cards = Suit.allCases.flatMap { suit in
            Rank.allCases.map { rank in PlayingCard(rank: rank, suit: suit) }
        }
    }

    mutating func shuffle() {
        cards.shuffle()
    }

    mutating func draw() -> PlayingCard? {
        guard !cards.isEmpty else { return nil }
        return cards.removeLast()
    }

    var count: Int { cards.count }
    var isEmpty: Bool { cards.isEmpty }
}

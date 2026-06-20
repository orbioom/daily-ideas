import Foundation
import Observation

// MARK: - Seeded RNG (SplitMix64)
struct SeedableRNG: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9e3779b97f4a7c15
        var z = state
        z = (z ^ (z >> 30)) &* 0xbf58476d1ce4e5b9
        z = (z ^ (z >> 27)) &* 0x94d049bb133111eb
        return z ^ (z >> 31)
    }
}

// MARK: - FlipEngine
@Observable
final class FlipEngine {

    enum CardState {
        case faceDown, faceUp, matched
    }

    struct Card: Identifiable {
        let id: UUID
        let pairID: Int
        let symbol: String
        var state: CardState = .faceDown
    }

    var cards: [Card] = []
    var moves: Int = 0
    var matchedPairs: Int = 0
    var totalPairs: Int = 0
    var faceUpCard: Card? = nil
    var isProcessingMatch: Bool = false

    var isComplete: Bool { matchedPairs == totalPairs && totalPairs > 0 }

    func setupGame(theme: CardTheme, gridSize: GridSize, seed: UInt64? = nil) {
        let pairs = gridSize.pairs
        let themeSymbols = Array(theme.symbols.prefix(pairs))

        var deck: [Card] = []
        for (index, symbol) in themeSymbols.enumerated() {
            deck.append(Card(id: UUID(), pairID: index, symbol: symbol))
            deck.append(Card(id: UUID(), pairID: index, symbol: symbol))
        }

        if let seed = seed {
            var rng = SeedableRNG(seed: seed)
            deck.shuffle(using: &rng)
        } else {
            deck.shuffle()
        }

        cards = deck
        moves = 0
        matchedPairs = 0
        totalPairs = pairs
        faceUpCard = nil
        isProcessingMatch = false
    }

    func flip(card: Card) {
        guard !isProcessingMatch else { return }
        guard let index = cards.firstIndex(where: { $0.id == card.id }) else { return }
        guard cards[index].state == .faceDown else { return }

        if faceUpCard == nil {
            cards[index].state = .faceUp
            faceUpCard = cards[index]
        } else {
            guard let firstCard = faceUpCard,
                  let firstIndex = cards.firstIndex(where: { $0.id == firstCard.id }) else {
                return
            }

            cards[index].state = .faceUp
            moves += 1

            if firstCard.pairID == cards[index].pairID {
                cards[index].state = .matched
                cards[firstIndex].state = .matched
                matchedPairs += 1
                faceUpCard = nil
            } else {
                isProcessingMatch = true
                let secondID = cards[index].id
                let firstID = firstCard.id

                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(800))
                    if let i1 = self.cards.firstIndex(where: { $0.id == firstID }),
                       let i2 = self.cards.firstIndex(where: { $0.id == secondID }) {
                        self.cards[i1].state = .faceDown
                        self.cards[i2].state = .faceDown
                    }
                    self.faceUpCard = nil
                    self.isProcessingMatch = false
                }
            }
        }
    }

    func reset() {
        cards = []
        moves = 0
        matchedPairs = 0
        totalPairs = 0
        faceUpCard = nil
        isProcessingMatch = false
    }
}

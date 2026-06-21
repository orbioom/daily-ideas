import Foundation

enum CribbageAI {
    // Choose 2 cards to discard from 6-card hand
    // ownCrib = true means discarding to our own crib (maximize crib value)
    // ownCrib = false means discarding to opponent's crib (minimize crib value)
    static func chooseDiscard(from hand: [Card], ownCrib: Bool, deck: [Card]) -> [Card] {
        var best: [Card] = []
        var bestScore = -Double.infinity
        let combos = combinations(hand, 2)
        for discard in combos {
            let kept = hand.filter { !discard.contains($0) }
            let handEV = CribbageScorer.expectedHandValue(keeping: kept, ownCrib: ownCrib, deck: deck)
            let cribEV = estimateCribValue(discard: discard, ownCrib: ownCrib, deck: deck)
            let total = ownCrib ? (handEV + cribEV) : (handEV - cribEV * 0.5)
            if total > bestScore {
                bestScore = total
                best = discard
            }
        }
        return best
    }

    private static func estimateCribValue(discard: [Card], ownCrib: Bool, deck: [Card]) -> Double {
        // Sample 20 random "other player discards" scenarios
        let remaining = deck.filter { !discard.contains($0) }
        var total = 0.0
        var count = 0
        // Sample combinations of 2 from remaining as opponent's discard + starter
        let pairs = combinations(Array(remaining.prefix(15)), 2)
        for opponentDiscard in pairs.prefix(20) {
            let cribHand = discard + opponentDiscard
            guard cribHand.count == 4 else { continue }
            let starters = remaining.filter { !opponentDiscard.contains($0) }
            for starter in starters.prefix(5) {
                let scored = CribbageScorer.scoreHand(cribHand, starter: starter, isCrib: true)
                total += Double(scored.total)
                count += 1
            }
        }
        return count > 0 ? total / Double(count) : 4.5
    }

    // Choose which card to play during pegging
    // Strategy: play to 15/31, avoid giving opponent 15/31, play pairs
    static func choosePeggingCard(hand: [Card], played: [Card], runningTotal: Int) -> Card {
        // Try to make 15
        for card in hand {
            if runningTotal + card.rank.value == 15 { return card }
        }
        // Try to make 31
        for card in hand {
            if runningTotal + card.rank.value == 31 { return card }
        }
        // Try to make a pair
        if let last = played.last {
            for card in hand {
                if card.rank == last.rank && runningTotal + card.rank.value <= 31 { return card }
            }
        }
        // Try to extend a run
        if played.count >= 2 {
            let lastTwo = Array(played.suffix(2)).map { $0.rank.rawValue }.sorted()
            for card in hand {
                let v = card.rank.value
                if v + runningTotal <= 31 {
                    let withCard = (lastTwo + [card.rank.rawValue]).sorted()
                    let isRun = (1..<withCard.count).allSatisfy { withCard[$0] == withCard[$0-1] + 1 }
                    if isRun { return card }
                }
            }
        }
        // Don't give opponent 15 or 31: avoid cards that leave total at 5 or 21
        let safe = hand.filter { c in
            let newTotal = runningTotal + c.rank.value
            return newTotal <= 31 && (15 - newTotal) > 3 && (31 - newTotal) > 3
        }
        if let pick = safe.first { return pick }
        // Fallback: lowest valid card
        return hand.filter { runningTotal + $0.rank.value <= 31 }.min(by: { $0.rank.value < $1.rank.value }) ?? hand[0]
    }
}

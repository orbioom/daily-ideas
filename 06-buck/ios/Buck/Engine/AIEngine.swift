import Foundation

struct AIEngine {
    let difficulty: String

    /// Decide whether to order up the flipped card in round 1.
    /// Counts trump cards in hand (including bowers) against a threshold by difficulty.
    func shouldOrderUp(hand: [Card], flippedCard: Card, seat: PlayerSeat, dealerSeat: PlayerSeat, difficulty: String) -> Bool {
        let potentialTrump = flippedCard.suit
        let trumpCards = hand.filter {
            $0.effectiveSuit(trump: potentialTrump) == potentialTrump
        }
        let threshold: Int
        switch difficulty {
        case "Beginner": threshold = 3
        case "Advanced": threshold = 2
        default: threshold = 2
        }
        return trumpCards.count >= threshold
    }

    /// Choose which suit to call in round 2. Returns nil if not calling.
    /// The excluded suit is the one turned down in round 1.
    func callSuit(hand: [Card], excludeSuit: Suit, screwTheDealer: Bool, isDealer: Bool) -> Suit? {
        var bestSuit: Suit? = nil
        var bestCount = 0
        for suit in Suit.allCases where suit != excludeSuit {
            let count = hand.filter { $0.effectiveSuit(trump: suit) == suit }.count
            if count > bestCount {
                bestCount = count
                bestSuit = suit
            }
        }
        // Screw-the-dealer: forced to call with any holding if dealer and others all passed
        let threshold = (isDealer && screwTheDealer) ? 1 : 2
        return bestCount >= threshold ? bestSuit : nil
    }

    /// Select the best card to play from the legal cards available.
    func chooseCard(hand: [Card], trick: Trick, trump: Suit, seat: PlayerSeat) -> Card {
        let legal = legalCards(hand: hand, trick: trick, trump: trump)
        guard !legal.isEmpty else { return hand[0] }

        // Leading the trick
        if trick.plays.isEmpty {
            // Lead highest trump if we have it, otherwise highest non-trump
            let trumpCards = legal.filter { $0.effectiveSuit(trump: trump) == trump }
            if !trumpCards.isEmpty {
                return trumpCards.max(by: { $0.trumpPower(trump: trump) < $1.trumpPower(trump: trump) }) ?? legal[0]
            }
            return legal.max(by: { $0.rank < $1.rank }) ?? legal[0]
        }

        // Following: try to win with lowest winning card, else dump lowest
        let winningCards = legal.filter { canWin(card: $0, trick: trick, trump: trump) }
        if !winningCards.isEmpty {
            // Prefer winning with lowest trump, else lowest winner by rank
            let trumpWinners = winningCards.filter { $0.effectiveSuit(trump: trump) == trump }
            if !trumpWinners.isEmpty {
                return trumpWinners.min(by: { $0.trumpPower(trump: trump) < $1.trumpPower(trump: trump) }) ?? winningCards[0]
            }
            return winningCards.min(by: { $0.rank < $1.rank }) ?? winningCards[0]
        }

        // Cannot win — dump lowest non-trump, or lowest trump if all trump
        let nonTrump = legal.filter { $0.effectiveSuit(trump: trump) != trump }
        return nonTrump.min(by: { $0.rank < $1.rank }) ?? legal.min(by: { $0.rank < $1.rank }) ?? legal[0]
    }

    /// Return the subset of hand cards that are legal to play given the current trick state.
    func legalCards(hand: [Card], trick: Trick, trump: Suit) -> [Card] {
        guard let led = trick.ledSuit else { return hand }
        // The effective led suit accounts for left bower leading as trump
        let effectiveLed = led == trump ? trump : led
        let followers = hand.filter { $0.effectiveSuit(trump: trump) == effectiveLed }
        return followers.isEmpty ? hand : followers
    }

    /// Returns true if playing `card` would beat every card already in the trick.
    private func canWin(card: Card, trick: Trick, trump: Suit) -> Bool {
        let cardIsTrump = card.effectiveSuit(trump: trump) == trump
        for play in trick.plays {
            let playIsTrump = play.card.effectiveSuit(trump: trump) == trump
            if playIsTrump && !cardIsTrump { return false }
            if playIsTrump && cardIsTrump {
                if play.card.trumpPower(trump: trump) >= card.trumpPower(trump: trump) { return false }
            }
            if !playIsTrump && !cardIsTrump {
                if play.card.rank >= card.rank && play.card.effectiveSuit(trump: trump) == trick.ledSuit { return false }
            }
        }
        return true
    }
}

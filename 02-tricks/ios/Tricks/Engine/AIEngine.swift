import Foundation

struct AIEngine {
    static func estimateBid(hand: [Card], difficulty: String) -> Int {
        var tricks = 0
        let spades = hand.filter { $0.suit == .spades }
        let nonSpades = hand.filter { $0.suit != .spades }
        tricks += spades.filter { $0.rank == .ace }.count
        tricks += spades.filter { $0.rank == .king && spades.count >= 2 }.count
        tricks += spades.filter { $0.rank == .queen && spades.count >= 3 }.count
        tricks += max(0, spades.count - 3)
        tricks += nonSpades.filter { $0.rank == .ace }.count
        if difficulty == "hard" {
            tricks += nonSpades.filter { $0.rank == .king }.count / 2
        }
        return max(1, min(tricks, 13))
    }

    static func chooseCard(hand: [Card], trick: Trick, seat: PlayerSeat, bids: [PlayerSeat: Bid], tricks: [PlayerSeat: Int], spadesBroken: Bool, difficulty: String) -> Card {
        let legal = legalCards(hand: hand, trick: trick, spadesBroken: spadesBroken)
        guard !legal.isEmpty else { return hand[0] }
        let bid = bids[seat] ?? Bid(amount: 2)

        // If nil bidder, try to avoid taking tricks
        if bid.isNil {
            if let avoid = legal.filter({ !willWinTrick(card: $0, trick: trick) }).min(by: { $0.rank < $1.rank }) {
                return avoid
            }
            return legal.min(by: { $0.rank < $1.rank }) ?? legal[0]
        }

        // Partner played nil - don't take tricks if partner is winning
        let partnerSeat = seat.partner
        if let partnerBid = bids[partnerSeat], partnerBid.isNil,
           let partnerCard = trick.cards.first(where: { $0.seat == partnerSeat })?.card,
           willWinTrick(card: partnerCard, trick: trick) {
            // Partner is winning, play low
            return legal.min(by: { $0.rank < $1.rank }) ?? legal[0]
        }

        if difficulty == "easy" {
            return legal.randomElement() ?? legal[0]
        }
        // Try to win if we need tricks
        let myTricks = tricks[seat] ?? 0
        let myBid = bid.amount
        if myTricks < myBid {
            if let winner = legal.filter({ willWinTrick(card: $0, trick: trick) }).max(by: { $0.rank < $1.rank }) {
                return winner
            }
        }
        // Otherwise play low
        return legal.min(by: { $0.rank < $1.rank }) ?? legal[0]
    }

    static func legalCards(hand: [Card], trick: Trick, spadesBroken: Bool) -> [Card] {
        guard !hand.isEmpty else { return [] }
        if trick.cards.isEmpty {
            if !spadesBroken && hand.contains(where: { $0.suit != .spades }) {
                return hand.filter { $0.suit != .spades }
            }
            return hand
        }
        guard let led = trick.ledSuit else { return hand }
        let following = hand.filter { $0.suit == led }
        return following.isEmpty ? hand : following
    }

    static func willWinTrick(card: Card, trick: Trick) -> Bool {
        guard !trick.cards.isEmpty, let led = trick.ledSuit else { return true }
        for (_, played) in trick.cards {
            if played.beats(card, led: led) { return false }
        }
        return true
    }
}

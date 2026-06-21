import Foundation

enum PlayerSeat: Int, CaseIterable, Codable { case south=0, west=1, north=2, east=3 }

extension PlayerSeat {
    var partner: PlayerSeat {
        switch self { case .south: return .north; case .north: return .south; case .east: return .west; case .west: return .east }
    }
    var isHuman: Bool { self == .south }
    var displayName: String { ["You","West","Partner","East"][rawValue] }
    var next: PlayerSeat { PlayerSeat(rawValue: (rawValue + 1) % 4) ?? .south }
}

struct Bid: Codable {
    var amount: Int // 0 = nil
    var isBlindNil: Bool = false
    var isNil: Bool { amount == 0 }
}

struct HandScore: Codable {
    var tricks: Int = 0
    var bid: Bid = Bid(amount: 2)
    var score: Int = 0
    var bags: Int = 0
}

struct Trick: Codable {
    var cards: [(seat: PlayerSeat, card: Card)] = []
    var ledSuit: Suit?
    var winner: PlayerSeat?

    var isFull: Bool { cards.count == 4 }

    mutating func play(card: Card, by seat: PlayerSeat) {
        if cards.isEmpty { ledSuit = card.suit }
        cards.append((seat, card))
    }

    mutating func determineWinner() {
        guard isFull, let led = ledSuit else { return }
        var winCard = cards[0].card
        var winSeat = cards[0].seat
        for (seat, card) in cards.dropFirst() {
            if card.beats(winCard, led: led) { winCard = card; winSeat = seat }
        }
        winner = winSeat
    }
}

struct GameState: Codable {
    var humanTeamScore: Int = 0
    var aiTeamScore: Int = 0
    var humanTeamBags: Int = 0
    var aiTeamBags: Int = 0
    var handsPlayed: Int = 0
    var dealer: PlayerSeat = .north
    var isGameOver: Bool = false
    var winner: String = ""

    mutating func applyHandScores(bids: [PlayerSeat: Bid], tricks: [PlayerSeat: Int], targetScore: Int) {
        // Human team (South+North)
        let humanNilS = bids[.south]?.isNil ?? false
        let humanNilN = bids[.north]?.isNil ?? false
        var humanScore = 0
        // Partnership bid (excluding nil bids)
        let partnerBid = (humanNilS ? 0 : bids[.south]?.amount ?? 0) + (humanNilN ? 0 : bids[.north]?.amount ?? 0)
        let humanTricks = (tricks[.south] ?? 0) + (tricks[.north] ?? 0)
        let partnerTricks = humanTricks - (humanNilS ? tricks[.south] ?? 0 : 0) - (humanNilN ? tricks[.north] ?? 0 : 0)
        if partnerBid > 0 {
            if partnerTricks >= partnerBid {
                humanScore += 10 * partnerBid + (partnerTricks - partnerBid)
                humanTeamBags += (partnerTricks - partnerBid)
            } else {
                humanScore -= 10 * partnerBid
            }
        }
        // Nil scores
        if humanNilS { humanScore += (tricks[.south] ?? 0) == 0 ? 100 : -100 }
        if humanNilN { humanScore += (tricks[.north] ?? 0) == 0 ? 100 : -100 }
        // Bags penalty
        if humanTeamBags >= 10 { humanScore -= 100; humanTeamBags -= 10 }
        humanTeamScore += humanScore

        // AI team (East+West)
        let aiBidE = bids[.east]?.amount ?? 0; let aiBidW = bids[.west]?.amount ?? 0
        let aiNilE = bids[.east]?.isNil ?? false; let aiNilW = bids[.west]?.isNil ?? false
        var aiScore = 0
        let aiPartnerBid = (aiNilE ? 0 : aiBidE) + (aiNilW ? 0 : aiBidW)
        let aiTricksTotal = (tricks[.east] ?? 0) + (tricks[.west] ?? 0)
        let aiPartnerTricks = aiTricksTotal - (aiNilE ? tricks[.east] ?? 0 : 0) - (aiNilW ? tricks[.west] ?? 0 : 0)
        if aiPartnerBid > 0 {
            if aiPartnerTricks >= aiPartnerBid {
                aiScore += 10 * aiPartnerBid + (aiPartnerTricks - aiPartnerBid)
                aiTeamBags += (aiPartnerTricks - aiPartnerBid)
            } else {
                aiScore -= 10 * aiPartnerBid
            }
        }
        if aiNilE { aiScore += (tricks[.east] ?? 0) == 0 ? 100 : -100 }
        if aiNilW { aiScore += (tricks[.west] ?? 0) == 0 ? 100 : -100 }
        if aiTeamBags >= 10 { aiScore -= 100; aiTeamBags -= 10 }
        aiTeamScore += aiScore
        handsPlayed += 1
        dealer = dealer.next

        // Check game over
        let maxScore = max(humanTeamScore, aiTeamScore)
        let minScore = min(humanTeamScore, aiTeamScore)
        if maxScore >= targetScore || minScore <= -200 {
            isGameOver = true
            winner = humanTeamScore > aiTeamScore ? "you" : "ai"
        }
    }
}

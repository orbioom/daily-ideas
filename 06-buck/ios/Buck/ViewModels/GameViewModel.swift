import SwiftUI
import SwiftData

@Observable final class GameViewModel {
    var hands: [PlayerSeat: [Card]] = [:]
    var humanTeamScore: Int = 0
    var aiTeamScore: Int = 0
    var currentTrick: Trick = Trick()
    var completedTricks: [Trick] = []
    var trump: Suit? = nil
    var makerSeat: PlayerSeat? = nil
    var dealerSeat: PlayerSeat = .north
    var currentLeader: PlayerSeat = .south
    var phase: GamePhase = .dealing
    var flippedCard: Card? = nil
    var kitty: [Card] = []
    var bidPhase: BidPhase = .round1
    var currentBidder: PlayerSeat = .south
    var handsPlayed: Int = 0
    var humanTricksThisHand: Int = 0
    var aiTricksThisHand: Int = 0
    var lastHandResult: HandResult? = nil
    var isGoingAlone: Bool = false
    var alonePlayer: PlayerSeat? = nil
    var difficulty: String = "Standard"
    var screwTheDealer: Bool = true
    var roundFirstBidderExcludedSuit: Suit? = nil
    var statusMessage: String = ""

    // MARK: - Game Lifecycle

    func startNewGame(difficulty: String, screwTheDealer: Bool) {
        self.difficulty = difficulty
        self.screwTheDealer = screwTheDealer
        humanTeamScore = 0
        aiTeamScore = 0
        handsPlayed = 0
        dealerSeat = .north
        phase = .dealing
        dealHand()
    }

    func dealHand() {
        var deck = Card.euchreDecks()
        var newHands: [PlayerSeat: [Card]] = [:]
        for seat in PlayerSeat.allCases {
            newHands[seat] = Array(deck.prefix(5))
            deck.removeFirst(5)
        }
        kitty = Array(deck.prefix(4))
        hands = newHands
        flippedCard = kitty.first
        humanTricksThisHand = 0
        aiTricksThisHand = 0
        completedTricks = []
        currentTrick = Trick()
        trump = nil
        makerSeat = nil
        isGoingAlone = false
        alonePlayer = nil
        bidPhase = .round1
        currentBidder = PlayerSeat(rawValue: (dealerSeat.rawValue + 1) % 4)!
        phase = .bidding
        roundFirstBidderExcludedSuit = nil
        statusMessage = "Bidding — \(currentBidder.displayName)'s turn"

        if !currentBidder.isHuman {
            scheduleAIBid()
        }
    }

    // MARK: - Bidding

    private func scheduleAIBid() {
        Task.detached { [weak self] in
            guard let self else { return }
            try? await Task.sleep(nanoseconds: 700_000_000)
            await MainActor.run { self.processAIBid() }
        }
    }

    /// Human orders up the flipped card (round 1). Optionally goes alone.
    func humanOrderUp(goAlone: Bool = false) {
        guard let flipped = flippedCard, phase == .bidding, bidPhase == .round1 else { return }
        trump = flipped.suit
        makerSeat = .south
        isGoingAlone = goAlone
        if goAlone { alonePlayer = .south }

        // Dealer must pick up the flipped card and discard their lowest non-trump
        if dealerSeat != .south {
            var dealerHand = hands[dealerSeat] ?? []
            dealerHand.append(flipped)
            let trumpSuit = flipped.suit
            if let discard = dealerHand
                .filter({ $0.effectiveSuit(trump: trumpSuit) != trumpSuit })
                .min(by: { $0.rank < $1.rank }) ?? dealerHand.min(by: { $0.rank < $1.rank }) {
                dealerHand.removeAll { $0.id == discard.id }
            }
            hands[dealerSeat] = dealerHand
        } else {
            // Human is dealer — auto-discard lowest non-trump from human hand
            var humanHand = hands[.south] ?? []
            humanHand.append(flipped)
            let trumpSuit = flipped.suit
            if let discard = humanHand
                .filter({ $0.effectiveSuit(trump: trumpSuit) != trumpSuit })
                .min(by: { $0.rank < $1.rank }) ?? humanHand.min(by: { $0.rank < $1.rank }) {
                humanHand.removeAll { $0.id == discard.id }
            }
            hands[.south] = humanHand
        }
        startPlay()
    }

    /// Human passes during bidding.
    func humanPass() {
        guard phase == .bidding else { return }
        advanceBidder()
    }

    /// Human calls a trump suit in round 2.
    func humanCallSuit(_ suit: Suit) {
        guard phase == .bidding, bidPhase == .round2 else { return }
        trump = suit
        makerSeat = .south
        startPlay()
    }

    func processAIBid() {
        guard phase == .bidding, !currentBidder.isHuman else { return }
        let aiEngine = AIEngine(difficulty: difficulty)
        let hand = hands[currentBidder] ?? []

        if bidPhase == .round1, let flipped = flippedCard {
            let shouldOrder = aiEngine.shouldOrderUp(
                hand: hand,
                flippedCard: flipped,
                seat: currentBidder,
                dealerSeat: dealerSeat,
                difficulty: difficulty
            )
            if shouldOrder {
                trump = flipped.suit
                makerSeat = currentBidder
                statusMessage = "\(currentBidder.displayName) ordered up \(flipped.suit.rawValue)"
                // If the bidding AI is also the dealer, they pick up the card
                if currentBidder == dealerSeat {
                    var dHand = hand
                    dHand.append(flipped)
                    let trumpSuit = flipped.suit
                    if let discard = dHand
                        .filter({ $0.effectiveSuit(trump: trumpSuit) != trumpSuit })
                        .min(by: { $0.rank < $1.rank }) {
                        dHand.removeAll { $0.id == discard.id }
                    }
                    hands[currentBidder] = dHand
                }
                startPlay()
                return
            }
        } else if bidPhase == .round2 {
            let excludeSuit = roundFirstBidderExcludedSuit ?? flippedCard?.suit ?? .spades
            let isDealer = currentBidder == dealerSeat
            if let called = aiEngine.callSuit(
                hand: hand,
                excludeSuit: excludeSuit,
                screwTheDealer: screwTheDealer,
                isDealer: isDealer
            ) {
                trump = called
                makerSeat = currentBidder
                statusMessage = "\(currentBidder.displayName) called \(called.rawValue) trump"
                startPlay()
                return
            }
        }
        advanceBidder()
    }

    private func advanceBidder() {
        let nextIdx = (currentBidder.rawValue + 1) % 4
        let nextBidder = PlayerSeat(rawValue: nextIdx)!
        let firstBidder = PlayerSeat(rawValue: (dealerSeat.rawValue + 1) % 4)!

        if bidPhase == .round1 {
            if nextBidder == firstBidder {
                // Completed round 1 with no one ordering up — move to round 2
                bidPhase = .round2
                roundFirstBidderExcludedSuit = flippedCard?.suit
                currentBidder = nextBidder
            } else {
                currentBidder = nextBidder
            }
        } else {
            if nextBidder == firstBidder {
                // All passed in round 2 — misdeal, redeal
                dealHand()
                return
            }
            currentBidder = nextBidder
        }

        statusMessage = "Bidding — \(currentBidder.displayName)'s turn"

        if !currentBidder.isHuman {
            scheduleAIBid()
        }
    }

    // MARK: - Play

    private func startPlay() {
        phase = .playing
        currentLeader = PlayerSeat(rawValue: (dealerSeat.rawValue + 1) % 4)!
        currentTrick = Trick()
        statusMessage = "\(trump.map { $0.rawValue } ?? "") trump — \(currentLeader.displayName) leads"
        if !currentLeader.isHuman {
            scheduleAIPlay()
        }
    }

    private func scheduleAIPlay() {
        Task.detached { [weak self] in
            guard let self else { return }
            try? await Task.sleep(nanoseconds: 600_000_000)
            await MainActor.run { self.playAICards() }
        }
    }

    func humanPlayCard(_ card: Card) {
        guard phase == .playing else { return }
        guard let trump = trump else { return }

        // Verify it's the human's turn in the play order
        let playOrder = rotatedOrder(starting: currentLeader)
        let playedSeats = currentTrick.plays.map(\.player)
        guard let nextSeat = playOrder.first(where: { !playedSeats.contains($0) }),
              nextSeat == .south else { return }

        let legal = AIEngine(difficulty: difficulty).legalCards(
            hand: hands[.south] ?? [],
            trick: currentTrick,
            trump: trump
        )
        guard legal.contains(where: { $0.id == card.id }) else { return }

        var hand = hands[.south] ?? []
        hand.removeAll { $0.id == card.id }
        hands[.south] = hand
        currentTrick.plays.append(TrickPlay(player: .south, card: card))

        // After human plays, let AI seats continue filling in
        scheduleAIPlay()
    }

    private func playAICards() {
        guard let trump = trump else { return }
        let playOrder = rotatedOrder(starting: currentLeader)
        let playedSeats = currentTrick.plays.map(\.player)

        for seat in playOrder {
            if playedSeats.contains(seat) { continue }
            if seat.isHuman { return }
            // Skip partner of the lone player when going alone
            if isGoingAlone, let alone = alonePlayer, seat == alone.partner { continue }

            let hand = hands[seat] ?? []
            let ai = AIEngine(difficulty: difficulty)
            let chosen = ai.chooseCard(hand: hand, trick: currentTrick, trump: trump, seat: seat)
            var updatedHand = hand
            updatedHand.removeAll { $0.id == chosen.id }
            hands[seat] = updatedHand
            currentTrick.plays.append(TrickPlay(player: seat, card: chosen))
        }

        // Lone-hand tricks need only 3 plays (partner sits out)
        let expectedPlays = isGoingAlone ? 3 : 4
        if currentTrick.plays.count >= expectedPlays {
            Task.detached { [weak self] in
                guard let self else { return }
                try? await Task.sleep(nanoseconds: 900_000_000)
                await MainActor.run { self.completeTrick() }
            }
        }
    }

    private func completeTrick() {
        guard let trump = trump, let winner = currentTrick.winner(trump: trump) else { return }
        completedTricks.append(currentTrick)
        if winner.isHumanTeam { humanTricksThisHand += 1 }
        else { aiTricksThisHand += 1 }
        currentLeader = winner
        currentTrick = Trick()
        statusMessage = "\(winner.displayName) wins the trick"

        if completedTricks.count >= 5 {
            endHand()
        } else {
            if !currentLeader.isHuman {
                scheduleAIPlay()
            }
        }
    }

    private func endHand() {
        guard let maker = makerSeat else { return }
        let result = HandResult(
            makerTeamIsHuman: maker.isHumanTeam,
            tricksHuman: humanTricksThisHand,
            tricksAI: aiTricksThisHand,
            wentAlone: isGoingAlone,
            alonePlayer: alonePlayer
        )
        lastHandResult = result
        humanTeamScore += result.humanTeamPoints
        aiTeamScore += result.aiTeamPoints
        handsPlayed += 1
        phase = .handOver

        if humanTeamScore >= 10 || aiTeamScore >= 10 {
            phase = .gameOver
        }
    }

    func nextHand() {
        lastHandResult = nil
        dealerSeat = PlayerSeat(rawValue: (dealerSeat.rawValue + 1) % 4)!
        dealHand()
    }

    // MARK: - Helpers

    func rotatedOrder(starting: PlayerSeat) -> [PlayerSeat] {
        let all = PlayerSeat.allCases
        let idx = all.firstIndex(of: starting)!
        return Array(all[idx...]) + Array(all[..<idx])
    }

    func saveGame(context: ModelContext) {
        let record = EuchreGameRecord(
            humanTeamScore: humanTeamScore,
            aiTeamScore: aiTeamScore,
            humanTeamWon: humanTeamScore >= 10,
            handsPlayed: handsPlayed,
            difficulty: difficulty,
            wentAlone: isGoingAlone
        )
        context.insert(record)
        try? context.save()
    }

    var isHumanTurn: Bool {
        guard phase == .playing else { return false }
        let playOrder = rotatedOrder(starting: currentLeader)
        let playedSeats = currentTrick.plays.map(\.player)
        return playOrder.first(where: { !playedSeats.contains($0) }) == .south
    }

    var legalHumanCards: Set<String> {
        guard let trump = trump, isHumanTurn else { return [] }
        let legal = AIEngine(difficulty: difficulty).legalCards(
            hand: hands[.south] ?? [],
            trick: currentTrick,
            trump: trump
        )
        return Set(legal.map(\.id))
    }
}

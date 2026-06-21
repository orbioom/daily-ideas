import SwiftUI
import SwiftData

enum HandPhase: Equatable {
    case dealing
    case bidding(seat: PlayerSeat)
    case playing(leader: PlayerSeat)
    case trickComplete(winner: PlayerSeat)
    case handComplete
    case gameOver
}

@Observable
final class GameViewModel {
    var hands: [PlayerSeat: [Card]] = [:]
    var bids: [PlayerSeat: Bid] = [:]
    var currentTrick: Trick = Trick()
    var completedTricks: [PlayerSeat: Int] = [:]
    var phase: HandPhase = .dealing
    var spadesBroken: Bool = false
    var gameState: GameState = GameState()
    var difficulty: String = "medium"
    var targetScore: Int = 500
    var humanBidAmount: Int = 2
    var statusMessage: String = ""
    var previousTrick: Trick? = nil

    func startNewHand(dealing hands: [PlayerSeat: [Card]]) {
        self.hands = hands
        bids = [:]
        currentTrick = Trick()
        completedTricks = [.south:0, .west:0, .north:0, .east:0]
        spadesBroken = false
        previousTrick = nil
        phase = .bidding(seat: gameState.dealer.next)
        statusMessage = "Bidding phase"
        processAIBidding()
    }

    func startGame(difficulty: String, target: Int) {
        self.difficulty = difficulty
        self.targetScore = target
        gameState = GameState()
        dealHand()
    }

    func dealHand() {
        var deck = Card.shuffledDeck()
        var h: [PlayerSeat: [Card]] = [:]
        for seat in PlayerSeat.allCases {
            h[seat] = Array(deck.prefix(13)); deck.removeFirst(13)
        }
        startNewHand(dealing: h)
    }

    private func processAIBidding() {
        guard case .bidding(let seat) = phase else { return }
        if seat == .south { return } // wait for human
        let hand = hands[seat] ?? []
        let bid = Bid(amount: AIEngine.estimateBid(hand: hand, difficulty: difficulty))
        bids[seat] = bid
        let next = seat.next
        if bids.count == 4 || next == gameState.dealer.next {
            // All bids placed
            let firstLeader = gameState.dealer.next
            phase = .playing(leader: firstLeader)
            statusMessage = "Your turn to play"
            processAIPlaying()
        } else {
            phase = .bidding(seat: next)
            processAIBidding()
        }
    }

    func humanBid(amount: Int, isNil: Bool) {
        guard case .bidding(let seat) = phase, seat == .south else { return }
        bids[.south] = Bid(amount: isNil ? 0 : amount)
        let next = seat.next
        if bids.count == 4 || next == gameState.dealer.next {
            if bids[.south] != nil {
                // Continue with remaining AI bids
                phase = .bidding(seat: next)
                processAIBidding()
            }
        } else {
            phase = .bidding(seat: next)
            processAIBidding()
        }
    }

    private func processAIPlaying() {
        guard case .playing(let leader) = phase else { return }
        // Find whose turn it is
        let playedSeats = Set(currentTrick.cards.map(\.seat))
        let order: [PlayerSeat] = [leader, leader.next, leader.next.next, leader.next.next.next]
        guard let nextSeat = order.first(where: { !playedSeats.contains($0) }) else { return }
        if nextSeat == .south { return } // human's turn
        Task.detached(priority: .userInitiated) {
            try? await Task.sleep(nanoseconds: 600_000_000)
            await MainActor.run {
                let hand = self.hands[nextSeat] ?? []
                let card = AIEngine.chooseCard(hand: hand, trick: self.currentTrick, seat: nextSeat, bids: self.bids, tricks: self.completedTricks, spadesBroken: self.spadesBroken, difficulty: self.difficulty)
                self.playCard(card, by: nextSeat)
            }
        }
    }

    func humanPlay(card: Card) {
        guard case .playing(let leader) = phase else { return }
        let playedSeats = Set(currentTrick.cards.map(\.seat))
        let order: [PlayerSeat] = [leader, leader.next, leader.next.next, leader.next.next.next]
        guard let nextSeat = order.first(where: { !playedSeats.contains($0) }), nextSeat == .south else { return }
        let legal = AIEngine.legalCards(hand: hands[.south] ?? [], trick: currentTrick, spadesBroken: spadesBroken)
        guard legal.contains(card) else { return }
        playCard(card, by: .south)
    }

    private func playCard(_ card: Card, by seat: PlayerSeat) {
        if card.suit == .spades { spadesBroken = true }
        currentTrick.play(card: card, by: seat)
        hands[seat]?.removeAll { $0 == card }
        if currentTrick.isFull {
            currentTrick.determineWinner()
            guard let winner = currentTrick.winner else { return }
            completedTricks[winner, default: 0] += 1
            let t = currentTrick
            phase = .trickComplete(winner: winner)
            statusMessage = "\(winner.displayName) won the trick"
            Task.detached(priority: .userInitiated) {
                try? await Task.sleep(nanoseconds: 1_200_000_000)
                await MainActor.run {
                    self.previousTrick = t
                    self.currentTrick = Trick()
                    if self.hands[.south]?.isEmpty ?? true {
                        self.endHand()
                    } else {
                        self.phase = .playing(leader: winner)
                        self.statusMessage = winner == .south ? "Your lead" : "\(winner.displayName) leads"
                        self.processAIPlaying()
                    }
                }
            }
        } else {
            processAIPlaying()
        }
    }

    private func endHand() {
        gameState.applyHandScores(bids: bids, tricks: completedTricks, targetScore: targetScore)
        if gameState.isGameOver {
            phase = .gameOver
            statusMessage = gameState.winner == "you" ? "You win the game!" : "AI wins the game!"
        } else {
            phase = .handComplete
            statusMessage = "Hand complete. Tap to deal next hand."
        }
    }

    func legalCardsForHuman() -> [Card] {
        guard case .playing(let leader) = phase else { return [] }
        let playedSeats = Set(currentTrick.cards.map(\.seat))
        let order: [PlayerSeat] = [leader, leader.next, leader.next.next, leader.next.next.next]
        guard let nextSeat = order.first(where: { !playedSeats.contains($0) }), nextSeat == .south else { return [] }
        return AIEngine.legalCards(hand: hands[.south] ?? [], trick: currentTrick, spadesBroken: spadesBroken)
    }

    var isHumanTurn: Bool {
        guard case .playing(let leader) = phase else { return false }
        let playedSeats = Set(currentTrick.cards.map(\.seat))
        let order: [PlayerSeat] = [leader, leader.next, leader.next.next, leader.next.next.next]
        return order.first(where: { !playedSeats.contains($0) }) == .south
    }

    var isHumanBidTurn: Bool {
        if case .bidding(let seat) = phase { return seat == .south }
        return false
    }
}

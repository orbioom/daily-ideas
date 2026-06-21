import Foundation
import SwiftUI

enum GamePhase {
    case dealing, discarding, cutting, pegging, showHand, showCrib, gameOver
}

enum PlayerTurn { case human, ai }

@Observable final class CribbageGame {
    var phase: GamePhase = .dealing
    var deck: [Card] = []
    var humanHand: [Card] = []
    var aiHand: [Card] = []
    var crib: [Card] = []
    var starter: Card? = nil
    var humanScore: Int = 0
    var aiScore: Int = 0
    var humanPegScore: Int = 0
    var aiPegScore: Int = 0
    var dealer: PlayerTurn = .human
    var peggingTurn: PlayerTurn = .human
    var peggingPile: [Card] = []
    var peggingTotal: Int = 0
    var humanPeggingHand: [Card] = []
    var aiPeggingHand: [Card] = []
    var lastScore: ScoredHand? = nil
    var lastPeggingScore: PeggingScore? = nil
    var message: String = "Welcome to Cribbage!"
    var selectedCards: Set<Card> = []
    var difficulty: Int = 1
    var winner: PlayerTurn? = nil
    var handBreakdown: [(label: String, points: Int)] = []
    var showBreakdown: Bool = false
    var consecutiveGos: Int = 0

    func startGame() {
        humanScore = 0
        aiScore = 0
        phase = .dealing
        winner = nil
        dealHands()
    }

    func dealHands() {
        deck = shuffledDeck()
        humanHand = Array(deck.prefix(6))
        aiHand = Array(deck.dropFirst(6).prefix(6))
        deck = Array(deck.dropFirst(12))
        crib = []
        starter = nil
        selectedCards = []
        phase = .discarding
        message = dealer == .human ? "Choose 2 cards for the crib" : "Choose 2 cards for the crib"

        // AI auto-discards
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(500))
            let aiDiscard = CribbageAI.chooseDiscard(from: aiHand, ownCrib: dealer == .ai, deck: deck)
            aiHand = aiHand.filter { !aiDiscard.contains($0) }
            crib.append(contentsOf: aiDiscard)
        }
    }

    func humanDiscard() {
        guard selectedCards.count == 2 else { return }
        let discards = Array(selectedCards)
        humanHand = humanHand.filter { !discards.contains($0) }
        crib.append(contentsOf: discards)
        selectedCards = []
        phase = .cutting
        message = "Tap to cut the deck"
    }

    func cutDeck() {
        starter = deck.randomElement()
        deck = deck.filter { $0 != starter }
        // His heels: jack starter = 2 pts for dealer
        if starter?.rank == .jack {
            if dealer == .human {
                humanScore += 2
                message = "His Heels! You score 2 pts"
            } else {
                aiScore += 2
                message = "His Heels! AI scores 2 pts"
            }
            checkWin()
        }
        humanPeggingHand = humanHand
        aiPeggingHand = aiHand
        peggingPile = []
        peggingTotal = 0
        consecutiveGos = 0
        peggingTurn = dealer == .human ? .ai : .human  // non-dealer goes first
        phase = .pegging
        if peggingTurn == .ai {
            message = "Pegging: AI plays first"
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(800))
                aiPeg()
            }
        } else {
            message = "Pegging: play a card"
        }
    }

    func humanPeg(card: Card) {
        guard phase == .pegging, peggingTurn == .human else { return }
        guard humanPeggingHand.contains(card) else { return }
        guard peggingTotal + card.rank.value <= 31 else { return }

        humanPeggingHand.removeAll { $0 == card }
        peggingPile.append(card)
        peggingTotal += card.rank.value
        consecutiveGos = 0

        let score = CribbageScorer.scorePegging(played: peggingPile, runningTotal: peggingTotal)
        if score.points > 0 {
            humanScore += score.points
            lastPeggingScore = score
            message = "You score \(score.points): \(score.description)"
            checkWin()
        }

        if peggingTotal == 31 {
            resetPegging()
        } else {
            peggingTurn = .ai
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(700))
                aiPeg()
            }
        }
    }

    private func aiPeg() {
        guard phase == .pegging else { return }
        let canPlay = aiPeggingHand.filter { peggingTotal + $0.rank.value <= 31 }

        if canPlay.isEmpty {
            consecutiveGos += 1
            if consecutiveGos >= 2 || humanPeggingHand.filter({ peggingTotal + $0.rank.value <= 31 }).isEmpty {
                // Last card: whoever played last gets 1
                humanScore += 1
                message = "Go! You score 1"
                resetPegging()
                return
            } else {
                message = "AI says Go — your turn"
                peggingTurn = .human
                return
            }
        }

        let card = CribbageAI.choosePeggingCard(hand: canPlay, played: peggingPile, runningTotal: peggingTotal)
        aiPeggingHand.removeAll { $0 == card }
        peggingPile.append(card)
        peggingTotal += card.rank.value
        consecutiveGos = 0

        let score = CribbageScorer.scorePegging(played: peggingPile, runningTotal: peggingTotal)
        if score.points > 0 {
            aiScore += score.points
            lastPeggingScore = score
            message = "AI scores \(score.points): \(score.description)"
            checkWin()
        }

        if peggingTotal == 31 {
            resetPegging()
        } else if humanPeggingHand.isEmpty && aiPeggingHand.isEmpty {
            aiScore += 1  // last card
            message = "AI gets last card +1"
            checkWin()
            endPegging()
        } else {
            peggingTurn = .human
            if humanPeggingHand.filter({ peggingTotal + $0.rank.value <= 31 }).isEmpty {
                consecutiveGos += 1
                message = "Go! Play has passed to AI"
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(600))
                    aiPeg()
                }
            } else {
                message = "Your turn to peg (total: \(peggingTotal))"
            }
        }
    }

    private func resetPegging() {
        peggingPile = []
        peggingTotal = 0
        consecutiveGos = 0
        if humanPeggingHand.isEmpty && aiPeggingHand.isEmpty {
            endPegging()
        } else {
            peggingTurn = dealer == .human ? .ai : .human
            if peggingTurn == .ai {
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(600))
                    aiPeg()
                }
            }
        }
    }

    private func endPegging() {
        phase = .showHand
        scoreHands()
    }

    private func scoreHands() {
        guard let s = starter else { return }

        let nonDealer: PlayerTurn = dealer == .human ? .ai : .human

        if nonDealer == .human {
            let scored = CribbageScorer.scoreHand(humanHand, starter: s, isCrib: false)
            humanScore += scored.total
            handBreakdown = scored.breakdown
            message = "Your hand scores \(scored.total)"
            checkWin()
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(2))
                let aiScored = CribbageScorer.scoreHand(aiHand, starter: s, isCrib: false)
                aiScore += aiScored.total
                message = "AI hand scores \(aiScored.total)"
                checkWin()
                try? await Task.sleep(for: .seconds(2))
                let cribScored = CribbageScorer.scoreHand(crib, starter: s, isCrib: true)
                if dealer == .human { humanScore += cribScored.total } else { aiScore += cribScored.total }
                message = "Crib scores \(cribScored.total) for \(dealer == .human ? "you" : "AI")"
                checkWin()
                try? await Task.sleep(for: .seconds(2))
                nextHand()
            }
        } else {
            let aiScored = CribbageScorer.scoreHand(aiHand, starter: s, isCrib: false)
            aiScore += aiScored.total
            message = "AI hand scores \(aiScored.total)"
            checkWin()
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(2))
                let scored = CribbageScorer.scoreHand(humanHand, starter: s, isCrib: false)
                humanScore += scored.total
                handBreakdown = scored.breakdown
                message = "Your hand scores \(scored.total)"
                checkWin()
                try? await Task.sleep(for: .seconds(2))
                let cribScored = CribbageScorer.scoreHand(crib, starter: s, isCrib: true)
                if dealer == .human { humanScore += cribScored.total } else { aiScore += cribScored.total }
                message = "Crib scores \(cribScored.total) for \(dealer == .human ? "you" : "AI")"
                checkWin()
                try? await Task.sleep(for: .seconds(2))
                nextHand()
            }
        }
    }

    private func nextHand() {
        dealer = dealer == .human ? .ai : .human
        dealHands()
    }

    private func checkWin() {
        if humanScore >= 121 {
            winner = .human
            phase = .gameOver
            message = "You win! 🎉"
        } else if aiScore >= 121 {
            winner = .ai
            phase = .gameOver
            message = "AI wins!"
        }
    }

    func toggleCardSelection(_ card: Card) {
        if selectedCards.contains(card) {
            selectedCards.remove(card)
        } else if selectedCards.count < 2 {
            selectedCards.insert(card)
        }
    }

    var canDiscard: Bool { selectedCards.count == 2 && phase == .discarding }
}

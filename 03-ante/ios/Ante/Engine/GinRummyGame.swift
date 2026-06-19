import Foundation
import SwiftUI

enum GamePhase {
    case dealing, playerTurn, opponentTurn, knockDecision, roundEnd, gameOver
}

enum DrawSource { case stock, discard }

@Observable
final class GinRummyGame {
    var deck = Deck()
    var playerHand: [PlayingCard] = []
    var opponentHand: [PlayingCard] = []
    var discardPile: [PlayingCard] = []
    var phase: GamePhase = .dealing
    var playerScore: Int = 0
    var opponentScore: Int = 0
    var roundNumber: Int = 1
    var winningScore: Int = 100
    var canKnock: Bool = false
    var message: String = ""
    var isAnimating: Bool = false
    var drawnCard: PlayingCard? = nil
    var selectedCard: PlayingCard? = nil
    var playerMelds: [Meld] = []
    var playerDeadwood: [PlayingCard] = []
    var opponentMelds: [Meld] = []
    var opponentDeadwood: [PlayingCard] = []
    var lastRoundResult: RoundResult? = nil
    var gameMode: String = "singlePlayer"
    var currentPlayer: Int = 0
    var deadHandMessage: String = ""
    var startTime: Date = Date()

    struct RoundResult {
        let knocker: String
        let knockerDeadwood: Int
        let defenderDeadwood: Int
        let isGin: Bool
        let isUndercut: Bool
        let pointsScored: Int
        let scorer: String
    }

    func startNewGame(mode: String, winScore: Int) {
        gameMode = mode
        winningScore = winScore
        playerScore = 0
        opponentScore = 0
        roundNumber = 1
        currentPlayer = 0
        startTime = Date()
        startNewRound()
    }

    func startNewRound() {
        deck = Deck()
        deck.shuffle()
        playerHand = []
        opponentHand = []
        discardPile = []
        drawnCard = nil
        selectedCard = nil
        phase = .dealing
        lastRoundResult = nil
        deadHandMessage = ""

        for _ in 0..<10 {
            if let c = deck.draw() { playerHand.append(c) }
            if let c = deck.draw() { opponentHand.append(c) }
        }
        if let c = deck.draw() { discardPile.append(c) }

        updateKnockability()
        phase = .playerTurn
        message = gameMode == "passAndPlay"
            ? "\(currentPlayer == 0 ? "Player 1" : "Player 2"): Draw a card"
            : "Draw a card to start"
    }

    func playerDraw(from source: DrawSource) {
        guard phase == .playerTurn, drawnCard == nil else { return }
        switch source {
        case .stock:
            guard let c = deck.draw() else { return }
            drawnCard = c
            message = "Now discard a card"
        case .discard:
            guard let c = discardPile.last else { return }
            discardPile.removeLast()
            drawnCard = c
            message = "Now discard a card"
        }
    }

    func playerDiscard(_ card: PlayingCard) {
        guard phase == .playerTurn, drawnCard != nil else { return }

        if let drawn = drawnCard {
            if card.id == drawn.id {
                discardPile.append(card)
                drawnCard = nil
            } else if let idx = playerHand.firstIndex(where: { $0.id == card.id }) {
                playerHand.remove(at: idx)
                playerHand.append(drawn)
                discardPile.append(card)
                drawnCard = nil
            } else {
                return
            }
        }

        updateKnockability()

        if gameMode == "singlePlayer" {
            phase = .opponentTurn
            message = "Opponent's turn..."
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.opponentTakeTurn()
            }
        } else {
            currentPlayer = currentPlayer == 0 ? 1 : 0
            phase = .playerTurn
            message = "\(currentPlayer == 0 ? "Player 1" : "Player 2"): Draw a card"
        }
    }

    func playerKnock() {
        guard phase == .playerTurn, canKnock else { return }
        let knockerName = gameMode == "passAndPlay" ? (currentPlayer == 0 ? "Player 1" : "Player 2") : "Player"
        let defenderHand = gameMode == "passAndPlay" ? (currentPlayer == 0 ? opponentHand : playerHand) : opponentHand
        resolveKnock(knocker: knockerName, knockerHand: playerHand, defenderHand: defenderHand)
    }

    private func resolveKnock(knocker: String, knockerHand: [PlayingCard], defenderHand: [PlayingCard]) {
        let (kMelds, kDW) = MeldDetector.findBestMelds(knockerHand)
        let (dMelds, dDW) = MeldDetector.findBestMelds(defenderHand)
        let kdv = MeldDetector.deadwoodValue(kDW)
        let ddv = MeldDetector.deadwoodValue(dDW)
        let isGin = kdv == 0
        let isUndercut = !isGin && ddv <= kdv

        let points: Int
        let scorer: String
        if isGin {
            points = ddv + 25
            scorer = knocker
        } else if isUndercut {
            points = abs(kdv - ddv) + 25
            scorer = (knocker == "Player" || knocker == "Player 1") ? "Opponent" : "Player"
        } else {
            points = kdv - ddv
            scorer = knocker
        }

        let result = RoundResult(
            knocker: knocker,
            knockerDeadwood: kdv,
            defenderDeadwood: ddv,
            isGin: isGin,
            isUndercut: isUndercut,
            pointsScored: abs(points),
            scorer: scorer
        )
        lastRoundResult = result

        if scorer == "Player" || scorer == "Player 1" {
            playerScore += abs(points)
        } else {
            opponentScore += abs(points)
        }

        playerMelds = kMelds
        playerDeadwood = kDW
        opponentMelds = dMelds
        opponentDeadwood = dDW

        phase = .roundEnd
    }

    private func opponentTakeTurn() {
        guard phase == .opponentTurn else { return }

        let topDiscard = discardPile.last
        var drew = false
        if let td = topDiscard {
            let testHand = opponentHand + [td]
            let (_, dw1) = MeldDetector.findBestMelds(testHand)
            let (_, dw0) = MeldDetector.findBestMelds(opponentHand)
            let testDeadwood = dw1.filter { $0.id != td.id }
            if MeldDetector.deadwoodValue(testDeadwood) < MeldDetector.deadwoodValue(dw0) {
                discardPile.removeLast()
                opponentHand.append(td)
                drew = true
            }
        }
        if !drew {
            if let c = deck.draw() { opponentHand.append(c) }
        }

        let (_, deadwood) = MeldDetector.findBestMelds(opponentHand)
        if let worst = deadwood.max(by: { $0.value < $1.value }),
           let idx = opponentHand.firstIndex(where: { $0.id == worst.id }) {
            let discarded = opponentHand.remove(at: idx)
            discardPile.append(discarded)
        }

        let (_, dw) = MeldDetector.findBestMelds(opponentHand)
        let dwv = MeldDetector.deadwoodValue(dw)
        if dwv <= 10 {
            resolveKnock(knocker: "Opponent", knockerHand: opponentHand, defenderHand: playerHand)
        } else if deck.isEmpty {
            deadHandMessage = "Dead hand — no winner this round"
            phase = .roundEnd
        } else {
            phase = .playerTurn
            message = "Your turn — draw a card"
        }
    }

    private func updateKnockability() {
        let (_, dw) = MeldDetector.findBestMelds(playerHand)
        canKnock = MeldDetector.deadwoodValue(dw) <= 10
    }

    func nextRound() {
        roundNumber += 1
        if playerScore >= winningScore || opponentScore >= winningScore {
            phase = .gameOver
        } else {
            startNewRound()
        }
    }

    var isGameOver: Bool { phase == .gameOver }

    var humanPlayerWon: Bool {
        playerScore >= winningScore && playerScore > opponentScore
    }

    var discardTop: PlayingCard? { discardPile.last }

    var elapsedSeconds: Int {
        Int(Date().timeIntervalSince(startTime))
    }

    func playerHandDeadwoodValue() -> Int {
        let (_, dw) = MeldDetector.findBestMelds(playerHand)
        return MeldDetector.deadwoodValue(dw)
    }
}

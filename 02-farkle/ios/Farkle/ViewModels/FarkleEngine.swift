import Foundation
import SwiftUI

@Observable
@MainActor
final class FarkleEngine {
    // MARK: - Types
    enum TurnPhase { case idle, rolled, banked, farkled, gameOver }
    struct Die: Identifiable {
        let id = UUID()
        var value: Int
        var held: Bool = false
        var locked: Bool = false  // contributed to score this roll, can't unselect
    }

    // MARK: - State
    private(set) var dice: [Die] = (0..<6).map { _ in Die(value: 1) }
    private(set) var phase: TurnPhase = .idle
    private(set) var turnScore: Int = 0
    private(set) var pendingScore: Int = 0  // scored from held dice this roll
    private(set) var playerScore: Int = 0
    private(set) var aiScore: Int = 0
    private(set) var isPlayerTurn: Bool = true
    private(set) var turnsPlayed: Int = 0
    private(set) var isAIThinking: Bool = false
    private(set) var aiActionMessage: String = ""
    var targetScore: Int = 10000
    var aiDifficulty: String = "Normal"

    private var diceLeft: Int { dice.filter { !$0.locked }.count }

    // MARK: - User Actions

    func startGame(target: Int, difficulty: String) {
        targetScore = target
        aiDifficulty = difficulty
        playerScore = 0
        aiScore = 0
        turnsPlayed = 0
        isPlayerTurn = true
        beginTurn()
    }

    func toggleHold(index: Int) {
        guard case .rolled = phase else { return }
        guard !dice[index].locked else { return }
        dice[index].held.toggle()
        recalcPending()
    }

    func roll() {
        guard case .rolled = phase, pendingScore > 0 else {
            if case .idle = phase { rollFresh() }
            return
        }
        // Lock held dice and roll the rest
        for i in dice.indices {
            if dice[i].held { dice[i].locked = true }
        }
        turnScore += pendingScore
        pendingScore = 0

        // If all dice locked, reset to full 6 (hot dice)
        if dice.allSatisfy({ $0.locked }) {
            dice = (0..<6).map { _ in Die(value: 1) }
        }

        rollFresh()
    }

    func bank() {
        guard case .rolled = phase else { return }
        guard pendingScore > 0 else { return }
        turnScore += pendingScore
        pendingScore = 0
        let total = turnScore
        turnScore = 0
        if isPlayerTurn {
            playerScore += total
            checkWin()
            if case .gameOver = phase { return }
            isPlayerTurn = false
            turnsPlayed += 1
            beginAITurn()
        }
    }

    // MARK: - Private

    private func beginTurn() {
        dice = (0..<6).map { _ in Die(value: 1) }
        turnScore = 0
        pendingScore = 0
        phase = .rolled
        rollFresh()
    }

    private func rollFresh() {
        for i in dice.indices where !dice[i].locked {
            dice[i].value = Int.random(in: 1...6)
            dice[i].held = false
        }
        let rolledValues = dice.filter { !$0.locked }.map { $0.value }
        if !hasScoringCombination(rolledValues) {
            phase = .farkled
            turnScore = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                guard let self else { return }
                if self.isPlayerTurn {
                    self.isPlayerTurn = false
                    self.turnsPlayed += 1
                    self.beginAITurn()
                } else {
                    self.isPlayerTurn = true
                    self.phase = .idle
                }
            }
        } else {
            phase = .rolled
        }
    }

    private func recalcPending() {
        let heldValues = dice.filter { $0.held && !$0.locked }.map { $0.value }
        pendingScore = scoreRoll(heldValues)
    }

    private func checkWin() {
        if playerScore >= targetScore {
            phase = .gameOver
        } else if aiScore >= targetScore {
            phase = .gameOver
        }
    }

    // MARK: - AI Turn

    private func beginAITurn() {
        isAIThinking = true
        aiActionMessage = "AI is rolling…"
        dice = (0..<6).map { _ in Die(value: 1) }
        turnScore = 0
        Task { await runAITurn() }
    }

    private func runAITurn() async {
        var aiTurnScore = 0
        var diceCount = 6

        while true {
            try? await Task.sleep(nanoseconds: 700_000_000)

            // Roll dice
            let rolled = (0..<diceCount).map { _ in Int.random(in: 1...6) }
            let mockDice = rolled.map { Die(value: $0) }
            dice = mockDice
            aiActionMessage = "AI rolled: \(rolled.sorted().map(String.init).joined(separator: ", "))"

            if !hasScoringCombination(rolled) {
                aiActionMessage = "AI farkled! No score this turn."
                try? await Task.sleep(nanoseconds: 800_000_000)
                break
            }

            // AI strategy: decide what to keep
            let (kept, keptScore) = bestKeep(rolled)
            aiTurnScore += keptScore
            diceCount = rolled.count - kept.count
            if diceCount == 0 { diceCount = 6 } // hot dice

            let threshold = aiThreshold(aiScore: aiScore, aiTurnScore: aiTurnScore, diceLeft: diceCount)
            aiActionMessage = "AI keeps scoring dice (+\(keptScore)). Turn: \(aiTurnScore)"

            try? await Task.sleep(nanoseconds: 600_000_000)

            if aiScore + aiTurnScore >= targetScore {
                // Bank for the win
                aiActionMessage = "AI banks \(aiTurnScore) for the win!"
                break
            }

            if aiTurnScore >= threshold || diceCount <= 1 {
                aiActionMessage = "AI banks \(aiTurnScore) points."
                break
            }
        }

        aiScore += aiTurnScore
        isAIThinking = false
        checkWin()
        if case .gameOver = phase { return }
        isPlayerTurn = true
        phase = .idle
    }

    private func aiThreshold(aiScore: Int, aiTurnScore: Int, diceLeft: Int) -> Int {
        switch aiDifficulty {
        case "Conservative": return 400
        case "Aggressive": return 1200
        default: return diceLeft <= 2 ? 500 : 800
        }
    }

    // MARK: - Scoring

    static func score(_ values: [Int]) -> Int {
        scoreRoll(values)
    }

    private func scoreRoll(_ values: [Int]) -> Int {
        Self.scoreRoll(values)
    }

    private func hasScoringCombination(_ values: [Int]) -> Bool {
        Self.scoreRoll(values) > 0
    }

    static func scoreRoll(_ values: [Int]) -> Int {
        guard !values.isEmpty else { return 0 }
        var counts = [Int: Int]()
        values.forEach { counts[$0, default: 0] += 1 }

        // Straight 1-6
        if values.count == 6 && counts.values.allSatisfy({ $0 == 1 }) { return 1500 }
        // Three pairs
        if values.count == 6 && counts.values.allSatisfy({ $0 == 2 }) { return 1500 }

        var total = 0
        for (face, count) in counts {
            if count >= 3 {
                let base = face == 1 ? 1000 : face * 100
                let multiplier: Int
                switch count {
                case 3: multiplier = 1
                case 4: multiplier = 2
                case 5: multiplier = 3
                case 6: multiplier = 4
                default: multiplier = 4
                }
                total += base * multiplier
            } else {
                if face == 1 { total += 100 * count }
                if face == 5 { total += 50 * count }
            }
        }
        return total
    }

    // Returns best subset to keep and its score
    private func bestKeep(_ values: [Int]) -> ([Int], Int) {
        var counts = [Int: Int]()
        values.forEach { counts[$0, default: 0] += 1 }

        // Straight or three-pairs: keep all
        if values.count == 6 && counts.values.allSatisfy({ $0 == 1 }) { return (values, 1500) }
        if values.count == 6 && counts.values.allSatisfy({ $0 == 2 }) { return (values, 1500) }

        var kept: [Int] = []
        var score = 0
        for (face, count) in counts {
            if count >= 3 {
                let base = face == 1 ? 1000 : face * 100
                let multiplier: Int = count == 3 ? 1 : count == 4 ? 2 : count == 5 ? 3 : 4
                score += base * multiplier
                kept += Array(repeating: face, count: count)
            } else {
                if face == 1 { score += 100 * count; kept += Array(repeating: 1, count: count) }
                if face == 5 { score += 50 * count; kept += Array(repeating: 5, count: count) }
            }
        }
        return (kept, score)
    }
}

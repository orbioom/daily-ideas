import Foundation
import SwiftData

@Model
final class FarkleGame {
    var id: UUID
    var date: Date
    var outcome: String     // "win", "loss"
    var turnsPlayed: Int
    var finalScore: Int
    var targetScore: Int

    init(outcome: String, turnsPlayed: Int, finalScore: Int, targetScore: Int) {
        self.id = UUID()
        self.date = Date()
        self.outcome = outcome
        self.turnsPlayed = turnsPlayed
        self.finalScore = finalScore
        self.targetScore = targetScore
    }
}

@Model
final class FarklePrefs {
    var onboardingDone: Bool
    var targetScore: Int      // 5000, 10000
    var aiDifficulty: String  // "Conservative", "Normal", "Aggressive"
    var hapticsEnabled: Bool
    var diceColor: String     // "Red", "Blue", "Black"

    init() {
        self.onboardingDone = false
        self.targetScore = 10000
        self.aiDifficulty = "Normal"
        self.hapticsEnabled = true
        self.diceColor = "Red"
    }
}

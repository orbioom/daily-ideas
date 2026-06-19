import Foundation
import SwiftData

@Model
final class HeartsGameRecord {
    var id: UUID
    var date: Date
    var finalScores: [Int]
    var playerWon: Bool
    var rounds: Int
    var aiLevelRaw: String

    init(finalScores: [Int], playerWon: Bool, rounds: Int, aiLevel: AILevel) {
        self.id = UUID()
        self.date = Date()
        self.finalScores = finalScores
        self.playerWon = playerWon
        self.rounds = rounds
        self.aiLevelRaw = aiLevel.rawValue
    }

    var aiLevel: AILevel { AILevel(rawValue: aiLevelRaw) ?? .medium }
    var playerScore: Int { finalScores.first ?? 0 }
}

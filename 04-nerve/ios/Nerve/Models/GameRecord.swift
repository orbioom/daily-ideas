import Foundation
import SwiftData

@Model
final class GameRecord {
    var id: UUID
    var date: Date
    var difficulty: String
    var secretCode: [Int]
    var guesses: [[Int]]
    var feedbacks: [[Int]]
    var isSolved: Bool
    var elapsedSeconds: Int

    init(difficulty: String, secretCode: [Int]) {
        self.id = UUID()
        self.date = Date()
        self.difficulty = difficulty
        self.secretCode = secretCode
        self.guesses = []
        self.feedbacks = []
        self.isSolved = false
        self.elapsedSeconds = 0
    }

    var guessCount: Int { guesses.count }
    var isComplete: Bool { isSolved || guesses.count >= NerveEngine.maxGuesses }
}

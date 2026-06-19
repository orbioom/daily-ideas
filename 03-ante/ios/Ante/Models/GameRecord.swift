import SwiftData
import Foundation

@Model final class GameRecord {
    var id: UUID
    var date: Date
    var opponentName: String
    var playerScore: Int
    var opponentScore: Int
    var roundsPlayed: Int
    var playerWon: Bool
    var gameDurationSeconds: Int
    var gameMode: String

    init(opponentName: String, mode: String) {
        self.id = UUID()
        self.date = Date()
        self.opponentName = opponentName
        self.playerScore = 0
        self.opponentScore = 0
        self.roundsPlayed = 0
        self.playerWon = false
        self.gameDurationSeconds = 0
        self.gameMode = mode
    }
}

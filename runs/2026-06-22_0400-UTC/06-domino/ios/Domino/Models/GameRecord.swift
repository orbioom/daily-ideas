import Foundation
import SwiftData

@Model
final class GameRecord {
    var id: UUID
    var date: Date
    var playerFinalScore: Int
    var aiFinalScore: Int
    var didPlayerWin: Bool
    var roundsPlayed: Int
    var difficulty: String
    var matchDurationSeconds: Int

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        playerFinalScore: Int,
        aiFinalScore: Int,
        didPlayerWin: Bool,
        roundsPlayed: Int,
        difficulty: String,
        matchDurationSeconds: Int
    ) {
        self.id = id
        self.date = date
        self.playerFinalScore = playerFinalScore
        self.aiFinalScore = aiFinalScore
        self.didPlayerWin = didPlayerWin
        self.roundsPlayed = roundsPlayed
        self.difficulty = difficulty
        self.matchDurationSeconds = matchDurationSeconds
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    var formattedDuration: String {
        let minutes = matchDurationSeconds / 60
        let seconds = matchDurationSeconds % 60
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        }
        return "\(seconds)s"
    }

    var resultLabel: String {
        didPlayerWin ? "Win" : "Loss"
    }
}

import Foundation
import SwiftData

@Model
class ScrawlRecord {
    var id: UUID
    var date: Date
    var teamNames: [String]
    var finalScores: [Int]
    var roundCount: Int
    var wordPackUsed: String

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        teamNames: [String],
        finalScores: [Int],
        roundCount: Int,
        wordPackUsed: String
    ) {
        self.id = id
        self.date = date
        self.teamNames = teamNames
        self.finalScores = finalScores
        self.roundCount = roundCount
        self.wordPackUsed = wordPackUsed
    }

    var winnerName: String? {
        guard !teamNames.isEmpty, !finalScores.isEmpty,
              teamNames.count == finalScores.count else { return nil }
        guard let maxScore = finalScores.max() else { return nil }
        let winnerIndex = finalScores.firstIndex(of: maxScore) ?? 0
        return teamNames[winnerIndex]
    }

    var winnerScore: Int? {
        finalScores.max()
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

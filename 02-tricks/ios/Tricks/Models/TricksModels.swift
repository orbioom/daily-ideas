import SwiftData
import Foundation

@Model final class SpadesGameRecord {
    var date: Date
    var humanTeamScore: Int
    var aiTeamScore: Int
    var humanTeamWon: Bool
    var handsPlayed: Int
    var difficulty: String

    init(date: Date = .now, humanTeamScore: Int, aiTeamScore: Int, humanTeamWon: Bool, handsPlayed: Int, difficulty: String) {
        self.date = date
        self.humanTeamScore = humanTeamScore
        self.aiTeamScore = aiTeamScore
        self.humanTeamWon = humanTeamWon
        self.handsPlayed = handsPlayed
        self.difficulty = difficulty
    }
}

@Model final class TricksSettings {
    var difficulty: String
    var soundEnabled: Bool
    var hapticEnabled: Bool
    var showCardValues: Bool
    var targetScore: Int
    var hasCompletedOnboarding: Bool

    init() {
        self.difficulty = "medium"
        self.soundEnabled = true
        self.hapticEnabled = true
        self.showCardValues = true
        self.targetScore = 500
        self.hasCompletedOnboarding = false
    }
}

import SwiftData
import Foundation

@Model final class EuchreGameRecord {
    var date: Date
    var humanTeamScore: Int
    var aiTeamScore: Int
    var humanTeamWon: Bool
    var handsPlayed: Int
    var difficulty: String
    var wentAlone: Bool

    init(date: Date = .now, humanTeamScore: Int, aiTeamScore: Int, humanTeamWon: Bool, handsPlayed: Int, difficulty: String, wentAlone: Bool = false) {
        self.date = date; self.humanTeamScore = humanTeamScore; self.aiTeamScore = aiTeamScore
        self.humanTeamWon = humanTeamWon; self.handsPlayed = handsPlayed
        self.difficulty = difficulty; self.wentAlone = wentAlone
    }
}

@Model final class BuckSettings {
    var difficulty: String          // "Beginner" | "Standard" | "Advanced"
    var hapticEnabled: Bool
    var showCardValues: Bool
    var animationsEnabled: Bool
    var screwTheDealer: Bool
    var hasCompletedOnboarding: Bool
    var isPro: Bool

    init() {
        difficulty = "Standard"; hapticEnabled = true; showCardValues = true
        animationsEnabled = true; screwTheDealer = true
        hasCompletedOnboarding = false; isPro = false
    }
}

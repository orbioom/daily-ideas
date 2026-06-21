import SwiftData
import Foundation

@Model final class TrainingRecord {
    var date: Date
    var scenario: String
    var correctAction: String
    var chosenAction: String
    var isCorrect: Bool
    var difficulty: String
    var sessionId: String

    init(date: Date = .now, scenario: String, correctAction: String, chosenAction: String, isCorrect: Bool, difficulty: String, sessionId: String = UUID().uuidString) {
        self.date = date
        self.scenario = scenario
        self.correctAction = correctAction
        self.chosenAction = chosenAction
        self.isCorrect = isCorrect
        self.difficulty = difficulty
        self.sessionId = sessionId
    }
}

@Model final class CountSettings {
    var difficulty: String
    var showHints: Bool
    var hapticEnabled: Bool
    var showCorrectOnWrong: Bool
    var decks: Int
    var hasCompletedOnboarding: Bool
    var isPro: Bool

    init() {
        difficulty = "Standard"
        showHints = true
        hapticEnabled = true
        showCorrectOnWrong = true
        decks = 6
        hasCompletedOnboarding = false
        isPro = false
    }
}

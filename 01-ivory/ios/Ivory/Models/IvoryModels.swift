import SwiftData
import Foundation

@Model final class GameRecord {
    var date: Date
    var playerColor: String
    var winner: String
    var blackDiscs: Int
    var whiteDiscs: Int
    var difficulty: String
    var durationSeconds: Int

    init(date: Date = .now, playerColor: String, winner: String, blackDiscs: Int, whiteDiscs: Int, difficulty: String, durationSeconds: Int = 0) {
        self.date = date
        self.playerColor = playerColor
        self.winner = winner
        self.blackDiscs = blackDiscs
        self.whiteDiscs = whiteDiscs
        self.difficulty = difficulty
        self.durationSeconds = durationSeconds
    }

    var playerWon: Bool { winner == playerColor }
    var isDraw: Bool { winner == "draw" }
}

@Model final class IvorySettings {
    var difficulty: String
    var showHints: Bool
    var showAnimations: Bool
    var hapticEnabled: Bool
    var playerColor: String
    var hasCompletedOnboarding: Bool

    init() {
        self.difficulty = "beginner"
        self.showHints = true
        self.showAnimations = true
        self.hapticEnabled = true
        self.playerColor = "black"
        self.hasCompletedOnboarding = false
    }
}

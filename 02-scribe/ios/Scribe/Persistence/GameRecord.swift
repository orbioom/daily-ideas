import SwiftData
import Foundation

@Model
final class GameRecord {
    var date: Date
    var score: Int
    var wordsPlayed: Int
    var highestWord: String
    var highestWordScore: Int
    var isDaily: Bool
    var durationSeconds: Int

    init(score: Int, wordsPlayed: Int, highestWord: String, highestWordScore: Int, isDaily: Bool, durationSeconds: Int) {
        self.date = Date()
        self.score = score
        self.wordsPlayed = wordsPlayed
        self.highestWord = highestWord
        self.highestWordScore = highestWordScore
        self.isDaily = isDaily
        self.durationSeconds = durationSeconds
    }
}

@Model
final class ScribePrefs {
    var hasSeenOnboarding: Bool
    var hapticsEnabled: Bool
    var showTileValues: Bool
    var isPro: Bool

    init() {
        self.hasSeenOnboarding = false
        self.hapticsEnabled = true
        self.showTileValues = true
        self.isPro = false
    }
}

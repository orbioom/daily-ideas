import Foundation
import SwiftData

@Model
final class GameResult {
    var deckName: String
    var date: Date
    var score: Int
    var totalSeen: Int
    var roundSeconds: Int
    var correctWords: [String]
    var passedWords: [String]

    init(deckName: String, date: Date = .now, score: Int, totalSeen: Int,
         roundSeconds: Int, correctWords: [String], passedWords: [String]) {
        self.deckName = deckName
        self.date = date
        self.score = score
        self.totalSeen = totalSeen
        self.roundSeconds = roundSeconds
        self.correctWords = correctWords
        self.passedWords = passedWords
    }
}

@Model
final class CustomDeck {
    var name: String
    var emoji: String
    var words: [String]
    var createdAt: Date

    init(name: String, emoji: String = "🎉", words: [String] = [], createdAt: Date = .now) {
        self.name = name
        self.emoji = emoji
        self.words = words
        self.createdAt = createdAt
    }
}

/// A playable deck — built-in or custom — normalized for the game engine.
struct PlayableDeck: Identifiable, Hashable {
    let id: String
    let name: String
    let emoji: String
    let blurb: String
    let words: [String]
    let isCustom: Bool
}

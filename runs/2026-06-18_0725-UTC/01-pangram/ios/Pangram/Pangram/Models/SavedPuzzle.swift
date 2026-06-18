import Foundation
import SwiftData

/// A puzzle the player has started (Daily or Practice). Stores enough to resume:
/// the letters, the originating seed index, and the words found so far. Solution sets
/// are recomputed from the seed at load time (never persisted in bulk).
@Model
final class SavedPuzzle {
    @Attribute(.unique) var id: String
    var dateKey: String
    var isDaily: Bool
    var centerLetter: String
    var outerLetters: [String]
    var seedIndex: Int
    var foundWords: [String]
    var createdAt: Date

    init(
        id: String,
        dateKey: String,
        isDaily: Bool,
        centerLetter: String,
        outerLetters: [String],
        seedIndex: Int,
        foundWords: [String] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.dateKey = dateKey
        self.isDaily = isDaily
        self.centerLetter = centerLetter
        self.outerLetters = outerLetters
        self.seedIndex = seedIndex
        self.foundWords = foundWords
        self.createdAt = createdAt
    }
}

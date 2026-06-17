import Foundation
import SwiftData

/// A bonus word the player has discovered, de-duplicated by `word`.
@Model
final class FoundBonusWord {
    @Attribute(.unique) var word: String
    var firstFoundLevel: String
    var foundAt: Date
    /// How many times the player has re-discovered this word across levels.
    var timesFound: Int

    init(word: String, firstFoundLevel: String, foundAt: Date = .now, timesFound: Int = 1) {
        self.word = word.uppercased()
        self.firstFoundLevel = firstFoundLevel
        self.foundAt = foundAt
        self.timesFound = timesFound
    }
}

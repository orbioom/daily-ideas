import SwiftData
import Foundation

@Model
class PackProgress {
    var category: String
    var difficulty: String
    var completedWords: [String]
    var lastPlayed: Date

    init(category: String, difficulty: String) {
        self.category = category
        self.difficulty = difficulty
        self.completedWords = []
        self.lastPlayed = Date()
    }

    var key: String { "\(category)_\(difficulty)" }
}

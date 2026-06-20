import Foundation
import SwiftData

@Model
final class HuntResult {
    var date: Date
    var score: Int
    var wordsFound: Int
    var totalWords: Int
    var duration: Int
    var isDaily: Bool

    init(
        date: Date = .now,
        score: Int,
        wordsFound: Int,
        totalWords: Int,
        duration: Int,
        isDaily: Bool = false
    ) {
        self.date = date
        self.score = score
        self.wordsFound = wordsFound
        self.totalWords = totalWords
        self.duration = duration
        self.isDaily = isDaily
    }
}

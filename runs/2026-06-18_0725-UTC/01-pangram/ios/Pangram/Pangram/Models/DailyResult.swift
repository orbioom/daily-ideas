import Foundation
import SwiftData

/// A completed (or in-progress, persisted) Daily outcome. Drives Stats and streaks.
@Model
final class DailyResult {
    @Attribute(.unique) var dateKey: String
    var score: Int
    var wordsFound: Int
    var pangrams: Int
    var reachedGenius: Bool
    var date: Date

    init(
        dateKey: String,
        score: Int,
        wordsFound: Int,
        pangrams: Int,
        reachedGenius: Bool,
        date: Date
    ) {
        self.dateKey = dateKey
        self.score = score
        self.wordsFound = wordsFound
        self.pangrams = pangrams
        self.reachedGenius = reachedGenius
        self.date = date
    }
}

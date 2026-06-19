import SwiftData
import Foundation

@Model
class DailyResult {
    var date: Date
    var word: String
    var category: String
    var difficulty: String
    var solved: Bool
    var hintsUsed: Int
    var timeElapsed: TimeInterval
    var timestamp: Date

    init(date: Date, word: String, category: String, difficulty: String, solved: Bool, hintsUsed: Int, timeElapsed: TimeInterval) {
        self.date = date
        self.word = word
        self.category = category
        self.difficulty = difficulty
        self.solved = solved
        self.hintsUsed = hintsUsed
        self.timeElapsed = timeElapsed
        self.timestamp = Date()
    }

    var dayKey: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: date)
    }
}

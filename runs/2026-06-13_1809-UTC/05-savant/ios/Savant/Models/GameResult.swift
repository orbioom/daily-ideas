import Foundation
import SwiftData

enum GameMode: String, Codable { case daily, practice }

@Model
final class GameResult {
    var id: UUID
    var modeRaw: String
    var categoryRaw: String?     // nil = mixed
    var score: Int
    var correct: Int
    var total: Int
    var date: Date
    var dayKey: String           // yyyy-MM-dd for daily de-duplication

    init(mode: GameMode, category: TriviaCategory?, score: Int, correct: Int, total: Int, date: Date = Date()) {
        self.id = UUID()
        self.modeRaw = mode.rawValue
        self.categoryRaw = category?.rawValue
        self.score = score
        self.correct = correct
        self.total = total
        self.date = date
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; f.timeZone = .current
        self.dayKey = f.string(from: date)
    }

    var mode: GameMode { GameMode(rawValue: modeRaw) ?? .practice }
    var category: TriviaCategory? { categoryRaw.flatMap { TriviaCategory(rawValue: $0) } }
    var accuracy: Double { total > 0 ? Double(correct) / Double(total) : 0 }
}

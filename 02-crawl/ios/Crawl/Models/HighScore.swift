import Foundation
import SwiftData

@Model
final class HighScore {
    var id: UUID
    var date: Date
    var score: Int
    var mode: String
    var applesEaten: Int

    init(score: Int, mode: String, applesEaten: Int) {
        self.id = UUID()
        self.date = Date()
        self.score = score
        self.mode = mode
        self.applesEaten = applesEaten
    }
}

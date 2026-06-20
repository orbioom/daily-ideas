import Foundation
import SwiftData

@Model
final class OrbResult {
    var date: Date
    var level: Int
    var score: Int
    var shotsUsed: Int
    var won: Bool

    init(date: Date = .now, level: Int, score: Int, shotsUsed: Int, won: Bool) {
        self.date = date
        self.level = level
        self.score = score
        self.shotsUsed = shotsUsed
        self.won = won
    }
}

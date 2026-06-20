import Foundation
import SwiftData

@Model
final class DropResult {
    var date: Date
    var outcome: String  // "win", "loss", "draw"
    var difficulty: Int  // 1, 2, 3
    var moves: Int

    init(date: Date = .now, outcome: String, difficulty: Int, moves: Int) {
        self.date = date
        self.outcome = outcome
        self.difficulty = difficulty
        self.moves = moves
    }
}

import Foundation
import SwiftData

@Model
final class GomokuResult {
    var id: UUID
    var date: Date
    var outcome: String      // "win", "loss", "draw"
    var difficulty: String   // "Easy", "Normal", "Hard"
    var moves: Int
    var durationSeconds: Int

    init(outcome: String, difficulty: String, moves: Int, durationSeconds: Int) {
        self.id = UUID()
        self.date = Date()
        self.outcome = outcome
        self.difficulty = difficulty
        self.moves = moves
        self.durationSeconds = durationSeconds
    }
}

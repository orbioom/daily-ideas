import Foundation
import SwiftData

@Model
final class GammonResult {
    var date: Date
    var outcome: String   // "win", "loss", "draw"
    var difficulty: Int   // 1=easy, 2=medium, 3=hard; 0 for 2-player
    var gameMoves: Int
    var mode: String      // "ai", "2player"
    var durationSeconds: Int

    init(
        date: Date = .now,
        outcome: String,
        difficulty: Int,
        gameMoves: Int,
        mode: String,
        durationSeconds: Int = 0
    ) {
        self.date = date
        self.outcome = outcome
        self.difficulty = difficulty
        self.gameMoves = gameMoves
        self.mode = mode
        self.durationSeconds = durationSeconds
    }
}

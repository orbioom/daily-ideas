import Foundation
import SwiftData

/// One finished (won or abandoned) game, kept for history and statistics.
@Model
final class GameRecord {
    var date: Date
    var won: Bool
    var score: Int
    var moves: Int
    var durationSeconds: Int
    var drawThree: Bool

    init(date: Date = .now, won: Bool, score: Int, moves: Int, durationSeconds: Int, drawThree: Bool) {
        self.date = date
        self.won = won
        self.score = score
        self.moves = moves
        self.durationSeconds = durationSeconds
        self.drawThree = drawThree
    }
}

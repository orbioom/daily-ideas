import Foundation
import SwiftData

/// A completed (won or abandoned) game, used to drive the Stats screen.
@Model
final class GameResult {
    @Attribute(.unique) var id: UUID
    var dealNumber: Int
    var won: Bool
    var durationSeconds: Int
    var moves: Int
    var date: Date

    init(id: UUID = UUID(),
         dealNumber: Int,
         won: Bool,
         durationSeconds: Int,
         moves: Int,
         date: Date = .now) {
        self.id = id
        self.dealNumber = dealNumber
        self.won = won
        self.durationSeconds = durationSeconds
        self.moves = moves
        self.date = date
    }
}

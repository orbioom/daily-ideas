import Foundation
import SwiftData

/// A single game within a match (e.g. an 11-point pickleball game). Games belong
/// to a `Match` via a cascade relationship and are ordered by `order`.
@Model
final class GameScore {
    var order: Int
    var myScore: Int
    var oppScore: Int

    init(order: Int, myScore: Int = 0, oppScore: Int = 0) {
        self.order = order
        self.myScore = max(0, myScore)
        self.oppScore = max(0, oppScore)
    }

    /// True when my side outscored the opponent in this game.
    var myWon: Bool { myScore > oppScore }

    /// A compact "11–7" style score line.
    var line: String { "\(myScore)–\(oppScore)" }
}

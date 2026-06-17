import Foundation
import SwiftData

/// A completed game's record. Drives the Stats screen.
@Model
final class GameResult {
    @Attribute(.unique) var id: UUID
    var date: Date
    var won: Bool
    /// 1, 2, or 4.
    var suitCount: Int
    var moves: Int
    var durationSeconds: Int
    var score: Int
    var wasDaily: Bool
    /// Present only for numbered deals.
    var dealNumber: Int?

    init(
        id: UUID = UUID(),
        date: Date = .now,
        won: Bool,
        suitCount: Int,
        moves: Int,
        durationSeconds: Int,
        score: Int,
        wasDaily: Bool,
        dealNumber: Int? = nil
    ) {
        self.id = id
        self.date = date
        self.won = won
        self.suitCount = suitCount
        self.moves = moves
        self.durationSeconds = durationSeconds
        self.score = score
        self.wasDaily = wasDaily
        self.dealNumber = dealNumber
    }

    /// The suit mode for this record (defaults to 1 if data is somehow malformed).
    var suitMode: SuitMode { SuitMode(rawValue: suitCount) ?? .one }
}

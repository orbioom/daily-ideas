import Foundation
import SwiftData

/// Single-row table holding the one in-progress game so it can be resumed on relaunch.
/// The board itself is stored as JSON-encoded `BoardState` Data.
@Model
final class SavedGame {
    @Attribute(.unique) var slot: Int   // always 0 — single-row marker
    var boardData: Data
    var layoutRaw: String
    var dealNumber: Int
    var isDaily: Bool
    var startedAt: Date
    var elapsedAccum: Double

    init(
        slot: Int = 0,
        boardData: Data,
        layoutRaw: String,
        dealNumber: Int,
        isDaily: Bool,
        startedAt: Date,
        elapsedAccum: Double
    ) {
        self.slot = slot
        self.boardData = boardData
        self.layoutRaw = layoutRaw
        self.dealNumber = dealNumber
        self.isDaily = isDaily
        self.startedAt = startedAt
        self.elapsedAccum = elapsedAccum
    }

    var layout: BoardLayout { BoardLayout(rawValue: layoutRaw) ?? .threePeaks }

    /// Decode the saved board state, if it is still valid.
    func decodedState() -> BoardState? {
        try? JSONDecoder().decode(BoardState.self, from: boardData)
    }
}

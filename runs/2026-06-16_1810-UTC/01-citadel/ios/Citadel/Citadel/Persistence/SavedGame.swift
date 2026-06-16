import Foundation
import SwiftData

/// The single in-progress game, persisted so it resumes on relaunch.
/// We keep at most one of these at a time.
@Model
final class SavedGame {
    @Attribute(.unique) var id: UUID
    var dealNumber: Int
    /// JSON-encoded `Board`.
    var boardData: Data
    var moveCount: Int
    var elapsedSeconds: Int
    var startedAt: Date
    var updatedAt: Date
    /// Remaining undos for the free tier (snapshot count is stored separately in the VM at runtime).
    var undosUsed: Int

    init(id: UUID = UUID(),
         dealNumber: Int,
         boardData: Data,
         moveCount: Int = 0,
         elapsedSeconds: Int = 0,
         startedAt: Date = .now,
         updatedAt: Date = .now,
         undosUsed: Int = 0) {
        self.id = id
        self.dealNumber = dealNumber
        self.boardData = boardData
        self.moveCount = moveCount
        self.elapsedSeconds = elapsedSeconds
        self.startedAt = startedAt
        self.updatedAt = updatedAt
        self.undosUsed = undosUsed
    }

    /// Decode the stored board, returning nil if the data is corrupt (handled calmly upstream).
    var decodedBoard: Board? {
        try? JSONDecoder().decode(Board.self, from: boardData)
    }
}

import Foundation

/// A fully serializable snapshot of an in-progress game, stored as `Data` in a
/// `SavedGame`. Captures the board (tiles + slots + removed flags), elapsed time,
/// move count, and the undo stack so a resumed game is identical.
struct SavedGameState: Codable {
    var layout: LayoutKind
    var slots: [LayoutSlot]
    var tiles: [PlacedTile]
    var elapsedSec: Int
    var moves: Int
    var undoStack: [UndoEntry]
    var hintsUsed: Int
    var shufflesUsed: Int
    var isDaily: Bool
    var dailyDateKey: String?

    struct UndoEntry: Codable {
        var idA: Int
        var idB: Int
    }

    var board: Board {
        Board(layout: layout, slots: slots, tiles: tiles)
    }

    /// Encode to `Data`. Returns nil on failure (never throws to caller).
    func encoded() -> Data? {
        try? JSONEncoder().encode(self)
    }

    static func decode(from data: Data) -> SavedGameState? {
        try? JSONDecoder().decode(SavedGameState.self, from: data)
    }
}

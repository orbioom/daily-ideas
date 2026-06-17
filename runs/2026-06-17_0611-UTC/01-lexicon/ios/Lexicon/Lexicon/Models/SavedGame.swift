import Foundation
import SwiftData

/// A resumable, in-progress (or freshly finished but unseen) game. Keyed by a
/// stable string so there is at most one row per puzzle:
///   - daily:    "daily-2026-06-17-len5"
///   - archive:  "archive-2026-06-10-len5"
///   - practice: "practice"
/// The board grid is stored as a Codable `BoardSnapshot` JSON-encoded into `gridJSON`.
@Model
final class SavedGame {
    @Attribute(.unique) var id: UUID
    @Attribute(.unique) var key: String
    var wordLength: Int
    var answer: String
    /// JSON-encoded `BoardSnapshot`.
    var gridJSON: String
    var currentRow: Int
    /// GameStatus rawValue.
    var statusRaw: String
    /// GameMode rawValue.
    var modeRaw: String
    /// The puzzle's calendar date for daily/archive (start of day); .now for practice.
    var puzzleDate: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        key: String,
        wordLength: Int,
        answer: String,
        gridJSON: String,
        currentRow: Int,
        status: GameStatus,
        mode: GameMode,
        puzzleDate: Date,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.key = key
        self.wordLength = wordLength
        self.answer = answer
        self.gridJSON = gridJSON
        self.currentRow = currentRow
        self.statusRaw = status.rawValue
        self.modeRaw = mode.rawValue
        self.puzzleDate = puzzleDate
        self.updatedAt = updatedAt
    }

    var status: GameStatus { GameStatus(rawValue: statusRaw) ?? .playing }
    var mode: GameMode { GameMode(rawValue: modeRaw) ?? .practice }

    func decodedBoard() -> BoardSnapshot? {
        guard let data = gridJSON.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(BoardSnapshot.self, from: data)
    }
}

/// Codable snapshot of the board grid: per-row typed letters and per-letter states.
/// `letters[r]` is the typed letters of row r (uppercase, possibly short while typing);
/// `states[r]` is the evaluated TileState raw values for submitted rows.
struct BoardSnapshot: Codable {
    var letters: [[String]]
    var states: [[Int]]
}

/// Centralizes load / save / clear of SavedGame rows by key.
enum SavedGameStore {

    static func encode(_ snapshot: BoardSnapshot) -> String? {
        guard let data = try? JSONEncoder().encode(snapshot) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// Fetch the saved game for a key, if any.
    static func fetch(key: String, in context: ModelContext) -> SavedGame? {
        let predicate = #Predicate<SavedGame> { $0.key == key }
        var descriptor = FetchDescriptor<SavedGame>(predicate: predicate)
        descriptor.fetchLimit = 1
        return (try? context.fetch(descriptor))?.first
    }

    /// Remove the saved game for a key, if present.
    static func clear(key: String, in context: ModelContext) {
        if let existing = fetch(key: key, in: context) {
            context.delete(existing)
            try? context.save()
        }
    }
}

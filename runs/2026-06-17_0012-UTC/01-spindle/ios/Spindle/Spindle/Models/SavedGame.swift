import Foundation
import SwiftData

/// At most one SavedGame exists: a JSON-encoded snapshot of the full board, so the
/// player can resume on relaunch. The board itself lives in `snapshotJSON`.
@Model
final class SavedGame {
    @Attribute(.unique) var id: UUID
    /// JSON-encoded `GameViewModel.Snapshot`.
    var snapshotJSON: String
    var suitCount: Int
    var moves: Int
    var score: Int
    var elapsedSeconds: Int
    var startedDate: Date
    /// Cached so the resume banner can describe the game without decoding JSON.
    var wasDaily: Bool

    init(
        id: UUID = UUID(),
        snapshotJSON: String,
        suitCount: Int,
        moves: Int,
        score: Int,
        elapsedSeconds: Int,
        startedDate: Date = .now,
        wasDaily: Bool = false
    ) {
        self.id = id
        self.snapshotJSON = snapshotJSON
        self.suitCount = suitCount
        self.moves = moves
        self.score = score
        self.elapsedSeconds = elapsedSeconds
        self.startedDate = startedDate
        self.wasDaily = wasDaily
    }

    var suitMode: SuitMode { SuitMode(rawValue: suitCount) ?? .one }

    /// Decodes the stored snapshot, or nil if the JSON is unreadable.
    func decodedSnapshot() -> GameViewModel.Snapshot? {
        guard let data = snapshotJSON.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(GameViewModel.Snapshot.self, from: data)
    }
}

/// Centralizes save/load/clear of the single SavedGame row.
enum SavedGameStore {

    /// Encodes a snapshot to a JSON string, or nil on failure.
    static func encode(_ snapshot: GameViewModel.Snapshot) -> String? {
        guard let data = try? JSONEncoder().encode(snapshot) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// Fetches the existing saved game, if any.
    static func fetch(in context: ModelContext) -> SavedGame? {
        let descriptor = FetchDescriptor<SavedGame>()
        return (try? context.fetch(descriptor))?.first
    }

    /// Saves (or replaces) the current game. Won games are not saved (nothing to resume).
    static func save(_ vm: GameViewModel, in context: ModelContext) {
        guard !vm.didWin else { clear(in: context); return }
        let snapshot = vm.makeSnapshot()
        guard let json = encode(snapshot) else { return }
        clear(in: context)
        let saved = SavedGame(
            snapshotJSON: json,
            suitCount: snapshot.engine.suitMode.rawValue,
            moves: snapshot.engine.moves,
            score: snapshot.engine.score,
            elapsedSeconds: snapshot.elapsedSeconds,
            startedDate: .now,
            wasDaily: snapshot.dealKind.isDaily
        )
        context.insert(saved)
        try? context.save()
    }

    /// Removes any saved game.
    static func clear(in context: ModelContext) {
        if let existing = fetch(in: context) {
            context.delete(existing)
            try? context.save()
        }
    }
}

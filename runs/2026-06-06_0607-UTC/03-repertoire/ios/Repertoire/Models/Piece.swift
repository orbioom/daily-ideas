import Foundation
import SwiftData

/// A musical work in the player's repertoire. Owns its ordered practice spots
/// (cascade-deleted) and is referenced by the sessions that worked on it.
@Model
final class Piece {
    var id: UUID
    var title: String
    var composer: String
    var instrument: String
    /// Raw value of `Difficulty` for tolerant decoding.
    var difficultyRaw: Int
    /// Raw value of `PieceStatus` for tolerant decoding.
    var statusRaw: String
    /// Target performance tempo in BPM (0 means "not set"). Bounded 20–300 when set.
    var targetTempo: Int
    var key: String
    var notes: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \PracticeSpot.piece)
    var spots: [PracticeSpot]

    /// Sessions that worked on this piece. Nullify on delete so a session row
    /// survives if a piece is removed (its time stays in totals as "other").
    @Relationship(deleteRule: .nullify, inverse: \SessionEntry.piece)
    var entries: [SessionEntry]

    init(id: UUID = UUID(),
         title: String,
         composer: String = "",
         instrument: String = "Piano",
         difficulty: Difficulty = .intermediate,
         status: PieceStatus = .learning,
         targetTempo: Int = 0,
         key: String = "",
         notes: String = "",
         createdAt: Date = .now) {
        self.id = id
        self.title = title
        self.composer = composer
        self.instrument = instrument
        self.difficultyRaw = difficulty.rawValue
        self.statusRaw = status.rawValue
        self.targetTempo = targetTempo
        self.key = key
        self.notes = notes
        self.createdAt = createdAt
        self.spots = []
        self.entries = []
    }

    // MARK: - Tolerant enum accessors

    var difficulty: Difficulty {
        get { Difficulty(rawValue: difficultyRaw) ?? .intermediate }
        set { difficultyRaw = newValue.rawValue }
    }

    var status: PieceStatus {
        get { PieceStatus(rawValue: statusRaw) ?? .learning }
        set { statusRaw = newValue.rawValue }
    }

    // MARK: - Derived

    /// Spots in their stored order.
    var orderedSpots: [PracticeSpot] {
        spots.sorted { $0.order < $1.order }
    }

    /// Average mastery across spots (0–5); nil when there are no spots.
    var averageMastery: Double? {
        guard !spots.isEmpty else { return nil }
        let total = spots.reduce(0) { $0 + $1.mastery }
        return Double(total) / Double(spots.count)
    }

    /// Most recent practice date across all sessions touching this piece.
    var lastPracticed: Date? {
        entries.compactMap { $0.session?.date }.max()
    }

    /// Whether a numeric target tempo has been set.
    var hasTarget: Bool { targetTempo >= Tempo.min }
}

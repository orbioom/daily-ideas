import Foundation
import SwiftData

/// A dated block of practice. A session logs total time and how it felt, and is
/// split across one or more pieces via its `SessionEntry` children (cascade-deleted).
/// This is the unit the insights aggregate over — streaks, weekly minutes, per-piece time.
@Model
final class PracticeSession {
    var id: UUID
    var date: Date
    /// Total wall-clock seconds of the session (sum of entries may differ if free practice).
    var durationSeconds: Int
    /// Free-text focus notes for the whole block.
    var focusNotes: String
    /// Raw value of `SessionQuality` for tolerant decoding (0 means "unrated").
    var qualityRaw: Int
    /// The tempo the metronome was driving when the session ran, in BPM (0 = none).
    var tempo: Int

    @Relationship(deleteRule: .cascade, inverse: \SessionEntry.session)
    var entries: [SessionEntry]

    init(id: UUID = UUID(),
         date: Date = .now,
         durationSeconds: Int = 0,
         focusNotes: String = "",
         quality: SessionQuality? = nil,
         tempo: Int = 0) {
        self.id = id
        self.date = date
        self.durationSeconds = durationSeconds
        self.focusNotes = focusNotes
        self.qualityRaw = quality?.rawValue ?? 0
        self.tempo = tempo
        self.entries = []
    }

    // MARK: - Tolerant enum accessor

    var quality: SessionQuality? {
        get { SessionQuality(rawValue: qualityRaw) }
        set { qualityRaw = newValue?.rawValue ?? 0 }
    }

    // MARK: - Derived

    /// Whole minutes of the session, never negative.
    var minutes: Int { max(0, durationSeconds) / 60 }

    /// Pieces worked on in this session, in entry order.
    var pieces: [Piece] {
        entries.compactMap { $0.piece }
    }
}

/// The join between a `PracticeSession` and a `Piece` — how much of a block went
/// to a given piece. Letting a session touch several pieces keeps the model honest
/// to how people actually practice (warm up on one, dig into another).
@Model
final class SessionEntry {
    var id: UUID
    /// Seconds of the parent session attributed to this piece.
    var durationSeconds: Int

    var session: PracticeSession?
    var piece: Piece?

    init(id: UUID = UUID(),
         durationSeconds: Int = 0) {
        self.id = id
        self.durationSeconds = durationSeconds
    }

    /// Whole minutes attributed to this piece, never negative.
    var minutes: Int { max(0, durationSeconds) / 60 }
}

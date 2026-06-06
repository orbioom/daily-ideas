import Foundation
import SwiftData

/// A reusable interval workout: an ordered list of `Segment`s plus a recorded log of
/// completed `Session`s. Deleting a routine cascade-deletes its segments and sessions.
@Model
final class Routine {
    var id: UUID
    var name: String
    /// A single SF Symbol name shown as the routine's glyph.
    var glyph: String
    /// Free-text note shown on the routine card / detail.
    var note: String
    var createdAt: Date
    /// Last time this routine was run to completion (nil if never).
    var lastRunAt: Date?

    @Relationship(deleteRule: .cascade, inverse: \Segment.routine)
    var segments: [Segment]

    @Relationship(deleteRule: .cascade, inverse: \Session.routine)
    var sessions: [Session]

    init(id: UUID = UUID(),
         name: String,
         glyph: String = "figure.run",
         note: String = "",
         createdAt: Date = .now,
         lastRunAt: Date? = nil) {
        self.id = id
        self.name = name
        self.glyph = glyph
        self.note = note
        self.createdAt = createdAt
        self.lastRunAt = lastRunAt
        self.segments = []
        self.sessions = []
    }

    /// Segments in builder order (ascending). Safe even if `order` values collide.
    var orderedSegments: [Segment] {
        segments.sorted { lhs, rhs in
            if lhs.order != rhs.order { return lhs.order < rhs.order }
            return lhs.id.uuidString < rhs.id.uuidString
        }
    }

    /// Sessions newest-first for history lists.
    var orderedSessions: [Session] {
        sessions.sorted { $0.startedAt > $1.startedAt }
    }

    /// Display name, never empty (falls back to "Untitled Routine").
    var displayName: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Untitled Routine" : trimmed
    }

    /// True when the routine has at least one segment and can therefore be run.
    var isRunnable: Bool { !segments.isEmpty }

    /// Total wall-clock duration in seconds, expanding all repeat groups.
    var totalDuration: Int {
        Timeline.flatten(orderedSegments).reduce(0) { $0 + $1.duration }
    }

    /// Total active "work" seconds across the expanded timeline.
    var totalWorkDuration: Int {
        Timeline.flatten(orderedSegments)
            .filter { $0.kind == .work }
            .reduce(0) { $0 + $1.duration }
    }

    /// Number of distinct steps after expansion (used for previews and labels).
    var stepCount: Int { Timeline.flatten(orderedSegments).count }
}

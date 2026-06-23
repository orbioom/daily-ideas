import Foundation
import SwiftData

/// A completed (or partially completed) breathing session, owned by the user.
@Model
final class BreathSession {
    /// Stable identifier.
    @Attribute(.unique) var id: UUID
    var startedAt: Date
    /// Seconds the user actually spent breathing.
    var durationSeconds: Double
    /// Pattern identity captured at session time (patterns are seed content).
    var patternID: String
    var patternName: String
    var styleRaw: String
    /// Number of full cycles / rounds completed.
    var cyclesCompleted: Int
    /// Whether the user reached the planned end (vs. ended early).
    var finished: Bool

    // Optional pre/post mood check-in values (1...5). `0` means "not recorded".
    var moodBefore: Int
    var moodAfter: Int

    /// One-to-one back-reference to a mood entry pair, if the user logged moods.
    /// Kept denormalized above for quick charting; this relationship lets the
    /// session own a richer note.
    var note: String

    init(id: UUID = UUID(),
         startedAt: Date = .now,
         durationSeconds: Double,
         patternID: String,
         patternName: String,
         styleRaw: String,
         cyclesCompleted: Int,
         finished: Bool,
         moodBefore: Int = 0,
         moodAfter: Int = 0,
         note: String = "") {
        self.id = id
        self.startedAt = startedAt
        self.durationSeconds = durationSeconds
        self.patternID = patternID
        self.patternName = patternName
        self.styleRaw = styleRaw
        self.cyclesCompleted = cyclesCompleted
        self.finished = finished
        self.moodBefore = moodBefore
        self.moodAfter = moodAfter
        self.note = note
    }

    var style: BreathStyle { BreathStyle(rawValue: styleRaw) ?? .coherent }

    var durationMinutes: Double { durationSeconds / 60.0 }

    /// Mood change, or nil if either side wasn't recorded.
    var moodDelta: Int? {
        guard moodBefore > 0, moodAfter > 0 else { return nil }
        return moodAfter - moodBefore
    }
}

import Foundation
import SwiftData

/// One night of sleep. Stored as two wall-clock instants plus quality metadata.
/// `night` is the calendar day the user *woke up* on — the canonical key for a night.
@Model
final class SleepLog {
    /// Stable identity for lazy lists.
    @Attribute(.unique) var id: UUID
    /// Calendar day the sleep is attributed to (the morning the user woke).
    var night: Date
    /// When the user got into bed / fell asleep.
    var bedTime: Date
    /// When the user got out of bed / woke.
    var wakeTime: Date
    /// Subjective quality 1...5.
    var quality: Int
    /// Number of times awoken in the night (>= 0).
    var awakenings: Int
    /// Optional free-text note.
    var note: String
    /// Free tags the user attaches (e.g. "caffeine", "screen", "exercise").
    var tags: [String]
    var createdAt: Date

    init(
        id: UUID = UUID(),
        night: Date,
        bedTime: Date,
        wakeTime: Date,
        quality: Int = 3,
        awakenings: Int = 0,
        note: String = "",
        tags: [String] = [],
        createdAt: Date = .now
    ) {
        self.id = id
        self.night = night
        self.bedTime = bedTime
        self.wakeTime = wakeTime
        self.quality = max(1, min(5, quality))
        self.awakenings = max(0, awakenings)
        self.note = note
        self.tags = tags
        self.createdAt = createdAt
    }

    /// Time in bed in hours, robust across midnight. Never negative.
    var durationHours: Double {
        let secs = wakeTime.timeIntervalSince(bedTime)
        // If wake is before bed (data entered oddly), assume crossed midnight.
        let adjusted = secs >= 0 ? secs : secs + 86_400
        return max(0, adjusted) / 3600.0
    }
}

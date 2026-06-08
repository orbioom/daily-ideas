import Foundation
import SwiftData

@Model
final class SleepLog {
    var id: UUID
    var bedTime: Date
    var wakeTime: Date
    var quality: Int        // 1...5
    var awakenings: Int     // >= 0
    var tags: [String]
    var note: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        bedTime: Date,
        wakeTime: Date,
        quality: Int,
        awakenings: Int = 0,
        tags: [String] = [],
        note: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.bedTime = bedTime
        self.wakeTime = wakeTime
        self.quality = max(1, min(5, quality))
        self.awakenings = max(0, awakenings)
        self.tags = tags
        self.note = note
        self.createdAt = createdAt
    }

    /// The calendar day the user woke up (used as the logical "night date").
    var nightDate: Date {
        Calendar.current.startOfDay(for: wakeTime)
    }

    /// Sleep duration in hours. Returns 0 if wakeTime <= bedTime.
    var durationHours: Double {
        let seconds = wakeTime.timeIntervalSince(bedTime)
        guard seconds > 0 else { return 0 }
        return seconds / 3600
    }
}
